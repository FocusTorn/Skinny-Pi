// Baseline creation and management
use crate::config::BaselineConfig;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};
use dashmap::DashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Baseline {
    pub created_at: u64,
    pub version: String,
    pub scan_path: String,
    pub remap_to: String,
    pub file_count: usize,
    pub is_delta: bool,
    pub files: HashMap<String, FileEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileEntry {
    pub path: String,
    pub track_mode: TrackMode,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum TrackMode {
    Content {
        checksum: String,
        content: String,
        size: u64,
        modified: u64,
        permissions: u32,
        owner: u32,
        group: u32,
    },
    Existence {
        size: u64,
        modified: u64,
        permissions: u32,
        owner: u32,
        group: u32,
    },
}

impl Baseline {
    pub fn new(scan_path: String, remap_to: String) -> Self {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
        
        let version = chrono::DateTime::<chrono::Local>::from(SystemTime::now())
            .format("%Y%m%d-%H%M%S")
            .to_string();
        
        Self {
            created_at: now,
            version,
            scan_path,
            remap_to,
            file_count: 0,
            is_delta: false,
            files: HashMap::new(),
        }
    }
    
    pub fn save(&self, data_dir: &Path) -> io::Result<PathBuf> {
        let baselines_dir = data_dir.join("baselines");
        fs::create_dir_all(&baselines_dir)?;
        
        let filename = if self.is_delta {
            format!("baseline-{}.json", self.version)
        } else {
            "baseline-initial.json".to_string()
        };
        
        let file_path = baselines_dir.join(filename);
        let json = serde_json::to_string_pretty(self)?;
        fs::write(&file_path, json)?;
        
        Ok(file_path)
    }
    
    pub fn load(data_dir: &Path, filename: &str) -> io::Result<Self> {
        let file_path = data_dir.join("baselines").join(filename);
        let content = fs::read_to_string(&file_path)?;
        let baseline: Baseline = serde_json::from_str(&content)?;
        Ok(baseline)
    }
    
    pub fn add_file(&mut self, path: String, entry: FileEntry) {
        self.files.insert(path.clone(), entry);
        self.file_count = self.files.len();
    }
}

/// Remap a physical path to a logical path
/// Example: "/media/pi/clean-pi/rootfs/etc/config.txt" -> "/etc/config.txt"
fn remap_path(physical_path: &str, scan_path: &str, remap_to: &str) -> String {
    if scan_path == remap_to {
        // No remapping needed
        return physical_path.to_string();
    }
    
    if let Some(suffix) = physical_path.strip_prefix(scan_path) {
        // Strip scan_path prefix and add remap_to prefix
        let suffix = suffix.trim_start_matches('/');
        if suffix.is_empty() {
            remap_to.to_string()
        } else if remap_to == "/" {
            // Special case: remapping to root, just add leading slash
            format!("/{}", suffix)
        } else {
            format!("{}/{}", remap_to, suffix)
        }
    } else {
        // Path doesn't start with scan_path, return as-is
        physical_path.to_string()
    }
}

pub fn scan_file(
    file_path: &Path,
    scan_path: &str,
    remap_to: &str,
    config: &BaselineConfig,
) -> io::Result<FileEntry> {
    let metadata = fs::metadata(file_path)?;
    let size = metadata.len();
    let modified = metadata
        .modified()?
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    
    // Get permissions (Unix only)
    #[cfg(unix)]
    use std::os::unix::fs::MetadataExt;
    #[cfg(unix)]
    let permissions = metadata.mode();
    #[cfg(unix)]
    let owner = metadata.uid();
    #[cfg(unix)]
    let group = metadata.gid();
    
    #[cfg(not(unix))]
    let permissions = 0;
    #[cfg(not(unix))]
    let owner = 0;
    #[cfg(not(unix))]
    let group = 0;
    
    // Get physical and remapped paths
    let physical_path = file_path.to_string_lossy().to_string();
    let remapped_path = remap_path(&physical_path, scan_path, remap_to);
    
    // Check if in existence-only directory
    let is_existence_only = config.existence_only_directories.iter()
        .any(|dir| remapped_path.starts_with(dir));
    
    // Check if extension is existence-only
    let is_existence_ext = if let Some(ext) = file_path.extension() {
        let ext_str = format!(".{}", ext.to_string_lossy());
        config.existence_only_extensions.iter()
            .any(|e| {
                // Handle pattern matching for ".so.*" (versioned shared libraries)
                if e == ".so.*" {
                    remapped_path.contains(".so.")
                } else {
                    remapped_path.ends_with(e) || ext_str == *e
                }
            })
    } else {
        false
    };
    
    // Check if executable (extensionless binary)
    #[cfg(unix)]
    let is_executable = (permissions & 0o111) != 0;
    #[cfg(not(unix))]
    let is_executable = false;
    
    // Determine tracking mode
    let track_mode = if is_existence_only || is_existence_ext || is_executable || size > config.content_size_limit {
        // Existence only
        TrackMode::Existence {
            size,
            modified,
            permissions,
            owner,
            group,
        }
    } else {
        // Try to read as text first
        match fs::read_to_string(file_path) {
            Ok(content) => {
                // Successfully read as text - store content
                let mut hasher = Sha256::new();
                hasher.update(content.as_bytes());
                let checksum = format!("{:x}", hasher.finalize());
                
                TrackMode::Content {
                    checksum,
                    content,
                    size,
                    modified,
                    permissions,
                    owner,
                    group,
                }
            }
            Err(_) => {
                // Can't read as text (binary file) - store existence only
                TrackMode::Existence {
                    size,
                    modified,
                    permissions,
                    owner,
                    group,
                }
            }
        }
    };
    
    // Store using remapped path
    Ok(FileEntry {
        path: remapped_path,
        track_mode,
    })
}

/// Check if a path should be excluded based on remapped path
fn should_exclude(physical_path: &str, scan_path: &str, remap_to: &str, config: &BaselineConfig) -> bool {
    let remapped = remap_path(physical_path, scan_path, remap_to);
    config.exclude_directories.iter()
        .any(|exclude| remapped.starts_with(exclude))
}

pub fn create_initial_baseline<F>(
    scan_path: &str,
    remap_to: &str,
    data_dir: &Path,
    config: &BaselineConfig,
    cancel_flag: Arc<AtomicBool>,
    progress_callback: F,
) -> io::Result<Baseline>
where
    F: FnMut(&str, usize, &str) + Send + Sync + 'static,
{
    // Normalize paths
    let scan_path_normalized = if scan_path == "/" {
        "/"
    } else {
        scan_path.trim_end_matches('/')
    };
    
    let remap_to_normalized = if remap_to.is_empty() {
        scan_path_normalized
    } else if remap_to == "/" {
        "/"
    } else {
        remap_to.trim_end_matches('/')
    };
    
    let scan_path_buf = PathBuf::from(scan_path_normalized);
    if !scan_path_buf.exists() {
        return Err(io::Error::new(
            io::ErrorKind::NotFound,
            format!("Scan path does not exist: {}", scan_path_normalized),
        ));
    }
    
    let mut baseline = Baseline::new(scan_path_normalized.to_string(), remap_to_normalized.to_string());
    
    // Use thread pool for parallel scanning
    let num_threads = num_cpus::get().max(1);
    let pool = threadpool::ThreadPool::new(num_threads);
    
    // Thread-safe collections
    let files = Arc::new(DashMap::new());
    let total_files = Arc::new(AtomicUsize::new(0));
    
    // Get top-level directories for parallel scanning
    let mut top_level_dirs = Vec::new();
    if let Ok(entries) = fs::read_dir(&scan_path_buf) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                if let Some(path_str) = path.to_str() {
                    // Check exclusion against remapped path
                    if !should_exclude(path_str, scan_path_normalized, remap_to_normalized, config) {
                        top_level_dirs.push(path);
                    }
                }
            }
        }
    }
    
    // Progress callback wrapper
    let progress_cb = Arc::new(Mutex::new(progress_callback));
    
    // Work-stealing queue: shared queue of directories/subdirectories to scan
    // Workers can pull from this when they finish their assigned work
    let work_queue: Arc<Mutex<Vec<PathBuf>>> = Arc::new(Mutex::new(top_level_dirs.clone()));
    let work_queue_size = Arc::new(AtomicUsize::new(top_level_dirs.len()));
    
    // Track work in progress (directories currently being scanned)
    let work_in_progress = Arc::new(AtomicUsize::new(0));
    
    // Scan directories in parallel using thread pool with work-stealing
    let (tx, rx) = std::sync::mpsc::channel();
    
    // Track active workers per directory
    let active_workers: Arc<DashMap<String, Arc<AtomicUsize>>> = Arc::new(DashMap::new());
    
    // Clone top_level_dirs for use in closures
    let top_level_dirs_clone = top_level_dirs.clone();
    
    // Submit work: create one worker task per top-level directory
    // Each worker will process its directory and then steal more work if available
    // If no top-level directories, don't spawn any workers (nothing to do)
    let num_workers = if top_level_dirs.is_empty() {
        0 // No work to do
    } else {
        num_threads.min(top_level_dirs.len()).max(1)
    };
    
    for _ in 0..num_workers {
        if cancel_flag.load(Ordering::Relaxed) {
            break;
        }
        
        let files_clone = Arc::clone(&files);
        let total_clone = Arc::clone(&total_files);
        let cancel_clone = Arc::clone(&cancel_flag);
        let progress_clone = Arc::clone(&progress_cb);
        let tx_clone = tx.clone();
        let config_clone = config.clone();
        let scan_path_str = scan_path_normalized.to_string();
        let remap_to_str = remap_to_normalized.to_string();
        let work_queue_clone = Arc::clone(&work_queue);
        let work_queue_size_clone = Arc::clone(&work_queue_size);
        let work_in_progress_clone = Arc::clone(&work_in_progress);
        let active_workers_clone = Arc::clone(&active_workers);
        let top_level_dirs_for_worker = top_level_dirs_clone.clone();
        let scan_path_buf_clone = scan_path_buf.clone();
        
        pool.execute(move || {
            // Define WorkGuard for tracking work in progress
            struct WorkGuard {
                counter: Arc<AtomicUsize>,
            }
            impl Drop for WorkGuard {
                fn drop(&mut self) {
                    self.counter.fetch_sub(1, Ordering::Relaxed);
                }
            }
            
            // Worker loop: keep stealing work until queue is empty and no work in progress
            let mut consecutive_empty_checks = 0u32;
            const MAX_CONSECUTIVE_EMPTY: u32 = 100; // After 1 second of empty checks, exit
            
            loop {
                if cancel_clone.load(Ordering::Relaxed) {
                    break;
                }
                
                // Try to get work from queue
                let dir_opt = {
                    let mut queue = work_queue_clone.lock().unwrap();
                    queue.pop()
                };
                
                let dir = match dir_opt {
                    Some(d) => {
                        // Got work - reset empty counter and update queue size
                        consecutive_empty_checks = 0;
                        work_queue_size_clone.fetch_sub(1, Ordering::Relaxed);
                        d
                    },
                    None => {
                        // Queue is empty - check if any work is still in progress
                        let queue_size = work_queue_size_clone.load(Ordering::Relaxed);
                        let in_progress = work_in_progress_clone.load(Ordering::Relaxed);
                        
                        // If queue is empty and no work in progress, we're done
                        if queue_size == 0 && in_progress == 0 {
                            break;
                        }
                        
                        consecutive_empty_checks += 1;
                        
                        // If we've checked many times and still see work in progress,
                        // but queue is empty, it might be that other workers are stuck
                        // Exit after max checks to prevent deadlock
                        if consecutive_empty_checks > MAX_CONSECUTIVE_EMPTY {
                            // Final check - if still stuck, exit anyway
                            let final_queue = work_queue_size_clone.load(Ordering::Relaxed);
                            let final_progress = work_in_progress_clone.load(Ordering::Relaxed);
                            if final_queue == 0 && final_progress == 0 {
                                break;
                            }
                            // If queue is still empty but work is in progress, something might be stuck
                            // However, we'll exit - the work guard will ensure work_in_progress is decremented
                            // when the recursive scan completes (even if it takes a long time)
                            break;
                        }
                        
                        // Work might still be in progress - yield and check again
                        std::thread::yield_now();
                        std::thread::sleep(std::time::Duration::from_millis(10));
                        continue;
                    }
                };
                
                // Mark work as in progress
                work_in_progress_clone.fetch_add(1, Ordering::Relaxed);
                
                // Use a guard to ensure work_in_progress is always decremented, even on panic/error
                let _work_guard = WorkGuard {
                    counter: Arc::clone(&work_in_progress_clone),
                };
                
                let dir_name = dir.to_string_lossy().to_string();
                let display_name = remap_path(&dir_name, &scan_path_str, &remap_to_str);
                
                // Track active worker for this directory
                let worker_count = active_workers_clone.entry(display_name.clone())
                    .or_insert_with(|| Arc::new(AtomicUsize::new(0)));
                worker_count.fetch_add(1, Ordering::Relaxed);
                
                // Notify worker started (only for top-level directories)
                if top_level_dirs_for_worker.iter().any(|d| d == &dir) {
                    if let Ok(mut cb) = progress_clone.try_lock() {
                        cb("scanning", 0, &format!("WorkerStarted: {}", display_name));
                    }
                }
                
                let mut local_files = HashMap::new();
                let file_count = Arc::new(AtomicUsize::new(0));
                let file_count_clone = Arc::clone(&file_count);
                
                // Scan this directory recursively with work-stealing support
                let progress_clone_cb = Arc::clone(&progress_clone);
                let file_count_clone_cb = Arc::clone(&file_count_clone);
                let display_name_cb = display_name.clone();
                
                // Throttle progress updates to reduce lock contention
                // Update every 100 files or every 50ms, whichever comes first
                let last_update = Arc::new(std::sync::Mutex::new((0, std::time::Instant::now())));
                let last_update_clone = Arc::clone(&last_update);
                
                let callback: Box<dyn Fn(&str) + Send + Sync> = Box::new(move |current_path| {
                    let count = file_count_clone_cb.fetch_add(1, Ordering::Relaxed) + 1;
                    
                    // Throttle: only update every 100 files or every 50ms
                    let should_update = {
                        let mut last = last_update_clone.lock().unwrap();
                        let now = std::time::Instant::now();
                        let file_diff = count.saturating_sub(last.0);
                        let time_diff = now.duration_since(last.1);
                        
                        if file_diff >= 100 || time_diff.as_millis() >= 50 {
                            last.0 = count;
                            last.1 = now;
                            true
                        } else {
                            false
                        }
                    };
                    
                    if should_update {
                        // Use try_lock to avoid blocking - if lock is held, skip this update
                        if let Ok(mut cb) = progress_clone_cb.try_lock() {
                            // Format: "WorkerName: file_count | current_path"
                            cb("scanning", count, &format!("{}: {} files | {}", display_name_cb, count, current_path));
                        }
                        // If lock is held, just skip this update - next one will go through
                    }
                });
                
                // Scan directory and add large subdirectories to work queue
                if let Err(_e) = walk_directory_worker_with_stealing(
                    &dir,
                    &dir,
                    &scan_path_str,
                    &remap_to_str,
                    &mut local_files,
                    &file_count,
                    &config_clone,
                    &cancel_clone,
                    &*callback,
                    &work_queue_clone,
                    &work_queue_size_clone,
                    &scan_path_str,
                    &remap_to_str,
                    &config_clone,
                ) {
                    // Error scanning directory - continue with next work item
                }
                
                // Work guard will automatically decrement work_in_progress when dropped
                
                // Merge results
                for (path, entry) in local_files {
                    files_clone.insert(path, entry);
                }
                
                let final_count = file_count_clone.load(Ordering::Relaxed);
                let total_so_far = total_clone.fetch_add(final_count, Ordering::Relaxed);
                
                // Update worker count
                if let Some(workers) = active_workers_clone.get(&display_name) {
                    workers.fetch_sub(1, Ordering::Relaxed);
                }
                
                // Notify completion (only for top-level directories)
                if top_level_dirs_for_worker.iter().any(|d| d == &dir) {
                    let display_name_clone = display_name.clone();
                    let _ = tx_clone.send((display_name_clone.clone(), final_count));
                    
                    if let Ok(mut cb) = progress_clone.try_lock() {
                        cb("scanning", total_so_far + final_count, &format!("Completed: {}", display_name));
                    }
                }
            }
        });
    }
    
    // Wait for thread pool to complete all tasks
    // The threadpool's join() will wait for all workers to finish
    // Workers will exit when queue is empty and no work is in progress
    pool.join();
    
    // After all workers have exited, check if there's any remaining work
    let final_in_progress = work_in_progress.load(Ordering::Relaxed);
    if final_in_progress > 0 {
        // Some work might still be in progress - wait a bit more for it to complete
        let mut wait_count = 0;
        while work_in_progress.load(Ordering::Relaxed) > 0 && wait_count < 100 {
            std::thread::sleep(std::time::Duration::from_millis(100));
            wait_count += 1;
        }
    }
    
    // Check if cancelled
    if cancel_flag.load(Ordering::Relaxed) {
        return Err(io::Error::new(io::ErrorKind::Interrupted, "Scan cancelled"));
    }
    
    // Drain any remaining messages from the channel (non-blocking)
    drop(tx);
    while let Ok(_) = rx.try_recv() {
        // Just drain the channel
    }
    
    // Collect results
    for entry in files.iter() {
        baseline.add_file(entry.key().clone(), entry.value().clone());
    }
    
    // Save baseline
    baseline.save(data_dir)?;
    
    Ok(baseline)
}

fn walk_directory_worker_with_stealing(
    root: &Path,
    current: &Path,
    scan_path: &str,
    remap_to: &str,
    results: &mut HashMap<String, FileEntry>,
    file_count: &Arc<AtomicUsize>,
    config: &BaselineConfig,
    cancel_flag: &Arc<AtomicBool>,
    progress_callback: &dyn Fn(&str),
    work_queue: &Arc<Mutex<Vec<PathBuf>>>,
    work_queue_size: &Arc<AtomicUsize>,
    scan_path_for_queue: &str,
    remap_to_for_queue: &str,
    config_for_queue: &BaselineConfig,
) -> io::Result<()>
{
    if cancel_flag.load(Ordering::Relaxed) {
        return Err(io::Error::new(io::ErrorKind::Interrupted, "Cancelled"));
    }
    
    // Check if current path should be excluded (check against remapped path)
    if let Some(current_str) = current.to_str() {
        if should_exclude(current_str, scan_path, remap_to, config) {
            return Ok(());
        }
    }
    
    let entries = match fs::read_dir(current) {
        Ok(entries) => entries,
        Err(_) => {
            // Skip directories we can't read
            return Ok(());
        }
    };
    
    for entry in entries {
        if cancel_flag.load(Ordering::Relaxed) {
            return Err(io::Error::new(io::ErrorKind::Interrupted, "Cancelled"));
        }
        
        let entry = match entry {
            Ok(e) => e,
            Err(_) => continue,
        };
        
        let path = entry.path();
        let metadata = match entry.metadata() {
            Ok(m) => m,
            Err(_) => continue,
        };
        
        // Avoid following symlinks
        if metadata.is_symlink() {
            continue;
        }
        
        if metadata.is_dir() {
            // Scan directories recursively
            // Note: Work-stealing for large directories removed to prevent freeze issues
            // Top-level work-stealing still works via the main work queue
            walk_directory_worker_with_stealing(
                root,
                &path,
                scan_path,
                remap_to,
                results,
                file_count,
                config,
                cancel_flag,
                progress_callback,
                work_queue,
                work_queue_size,
                scan_path_for_queue,
                remap_to_for_queue,
                config_for_queue,
            )?;
        } else if metadata.is_file() {
            // Scan file
            match scan_file(&path, scan_path, remap_to, config) {
                Ok(file_entry) => {
                    // Calculate relative path from root for storage key
                    let relative_path = path.strip_prefix(root)
                        .unwrap_or(&path)
                        .to_string_lossy()
                        .to_string();
                    
                    // Use remapped path for storage
                    let storage_path = remap_path(&relative_path, scan_path, remap_to);
                    
                    results.insert(storage_path, file_entry);
                    file_count.fetch_add(1, Ordering::Relaxed);
                    
                    // Report progress
                    if let Some(path_str) = path.to_str() {
                        progress_callback(path_str);
                    }
                }
                Err(_) => {
                    // Silently skip files we can't scan
                }
            }
        }
    }
    
    Ok(())
}
