// Chamon application state
use crate::config::Config;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::mpsc;
use std::time::SystemTime;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ViewMode {
    Dashboard,
    Changes,
    Baselines,
}

#[derive(Debug, Clone)]
pub struct BaselineItem {
    pub version: String,
    pub file_count: usize,
    pub is_initial: bool,
    pub is_active: bool,
}

// Use shared popup component
use tui_components::Popup;

/// Progress update messages sent from worker threads to main thread
#[derive(Debug, Clone)]
pub enum ProgressUpdate {
    /// Worker started scanning a directory
    WorkerStarted { name: String },
    /// Worker progress update
    WorkerProgress { name: String, file_count: usize, current_path: String },
    /// Worker completed a directory
    WorkerCompleted { name: String, file_count: usize },
    /// Overall file count update
    FilesProcessed { count: usize },
    /// Package database progress
    PackageProgress { processed: usize, total: usize },
    /// Phase change
    PhaseChanged { phase: String },
    /// Baseline creation completed
    BaselineCompleted { success: bool, message: String },
}

pub struct App {
    pub config: Config,
    pub data_dir: PathBuf,
    pub current_view: ViewMode,
    pub should_quit: bool,
    
    // Baselines view state
    pub baselines: Vec<BaselineItem>,
    pub selected_baseline: usize,
    pub active_baseline: usize,
    pub comparison_results: Option<ComparisonResults>,
    
    // Popup state
    pub popup: Option<Popup>,
    
    // Baseline creation progress tracking
    pub creating_baseline: bool,
    pub creating_initial: bool,
    pub baseline_progress: Vec<(String, usize, String)>, // (worker_name, file_count, current_path)
    pub baseline_completed: Vec<(String, usize)>, // (dir_name, file_count)
    pub baseline_files_processed: usize,
    pub baseline_estimated_total: Option<usize>,
    pub baseline_start_time: Option<SystemTime>,
    pub package_db_progress: Option<(usize, usize)>, // (processed, total)
    pub baseline_phase: String, // "scanning", "packaging", "finalizing"
    
    // Channel for receiving progress updates from background thread
    pub progress_rx: Option<mpsc::Receiver<ProgressUpdate>>,
}

#[derive(Debug, Clone)]
pub struct ComparisonResults {
    pub changed: usize,
    pub new: usize,
    pub deleted: usize,
    pub packages_added: usize,
    pub packages_removed: usize,
    pub packages_upgraded: usize,
}

impl App {
    pub fn new() -> Self {
        let config_content = include_str!("../config.yaml");
        let config: Config = serde_yaml::from_str(config_content)
            .unwrap_or_else(|_| Config::default());
        
        // Use data directory relative to project or in a standard location
        let data_dir = PathBuf::from("/root/_playground/rust/dev/chamon/data");
        
        // Load baselines from disk
        let mut baselines = Vec::new();
        let baselines_dir = data_dir.join("baselines");
        
        // Load initial baseline if it exists (saved in baselines_dir as baseline-initial.json)
        let initial_path = baselines_dir.join("baseline-initial.json");
        if initial_path.exists() {
            if let Ok(baseline) = crate::baseline::Baseline::load(&data_dir, "baseline-initial.json") {
                baselines.push(BaselineItem {
                    version: "Initial Baseline".to_string(),
                    file_count: baseline.file_count,
                    is_initial: true,
                    is_active: false, // Will be set based on active_baseline index
                });
            }
        }
        
        // Load delta baselines
        if baselines_dir.exists() {
            if let Ok(entries) = std::fs::read_dir(&baselines_dir) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    if let Some(filename) = path.file_name().and_then(|n| n.to_str()) {
                        // Skip initial baseline (already loaded)
                        if filename == "baseline-initial.json" {
                            continue;
                        }
                        
                        // Load delta baselines (format: baseline-YYYYMMDD-HHMMSS.json)
                        if filename.starts_with("baseline-") && filename.ends_with(".json") {
                            if let Ok(baseline) = crate::baseline::Baseline::load(&data_dir, filename) {
                                // Extract version from filename or use baseline version
                                let version = baseline.version.clone();
                                baselines.push(BaselineItem {
                                    version,
                                    file_count: baseline.file_count,
                                    is_initial: false,
                                    is_active: false, // Will be set based on active_baseline index
                                });
                            }
                        }
                    }
                }
            }
        }
        
        // Sort baselines: deltas first (newest first), then initial baseline at the end
        baselines.sort_by(|a, b| {
            if a.is_initial && !b.is_initial {
                std::cmp::Ordering::Greater // Initial goes to end
            } else if !a.is_initial && b.is_initial {
                std::cmp::Ordering::Less
            } else if !a.is_initial && !b.is_initial {
                // Both deltas - sort by version (newest first)
                b.version.cmp(&a.version)
            } else {
                std::cmp::Ordering::Equal
            }
        });
        
        // Set active baseline (first delta, or initial if no deltas)
        let active_baseline = if baselines.iter().any(|b| !b.is_initial) {
            baselines.iter().position(|b| !b.is_initial).unwrap_or(0)
        } else {
            baselines.len().saturating_sub(1)
        };
        
        // Mark active baseline
        if let Some(b) = baselines.get_mut(active_baseline) {
            b.is_active = true;
        }
        
        Self {
            config,
            data_dir,
            current_view: ViewMode::Baselines,
            should_quit: false,
            baselines,
            selected_baseline: 0,
            active_baseline,
            comparison_results: None,
            popup: None,
            creating_baseline: false,
            creating_initial: false,
            baseline_progress: Vec::new(),
            baseline_completed: Vec::new(),
            baseline_files_processed: 0,
            baseline_estimated_total: None,
            baseline_start_time: None,
            package_db_progress: None,
            baseline_phase: "scanning".to_string(),
            progress_rx: None,
        }
    }
    
    pub fn show_delete_confirmation(&mut self) {
        if let Some(baseline) = self.baselines.get(self.selected_baseline) {
            self.popup = Some(tui_components::Popup::confirm(
                "Delete Baseline".to_string(),
                format!("Delete baseline: {}?", baseline.version),
            ));
        }
    }
    
    pub fn popup_move_left(&mut self) {
        if let Some(popup) = &mut self.popup {
            match &mut popup.popup_type {
                tui_components::PopupType::Confirm { selected, .. } => {
                    if *selected > 0 {
                        *selected -= 1;
                    }
                }
                _ => {}
            }
        }
    }
    
    pub fn popup_move_right(&mut self) {
        if let Some(popup) = &mut self.popup {
            match &mut popup.popup_type {
                tui_components::PopupType::Confirm { selected, .. } => {
                    if *selected < 1 {
                        *selected += 1;
                    }
                }
                _ => {}
            }
        }
    }
    
    pub fn popup_confirm(&mut self) {
        if let Some(popup) = self.popup.take() {
            match popup.popup_type {
                tui_components::PopupType::Confirm { message, selected, .. } => {
                    if selected == 0 {
                        // Yes was selected - extract version from message
                        // Message format: "Delete baseline: {version}?"
                        if let Some(version) = message.strip_prefix("Delete baseline: ").and_then(|s| s.strip_suffix("?")) {
                            self.delete_baseline(version);
                        }
                    }
                }
                _ => {}
            }
        }
    }
    
    pub fn popup_cancel(&mut self) {
        self.popup = None;
    }
    
    fn delete_baseline(&mut self, version: &str) {
        // Remove from list
        self.baselines.retain(|b| b.version != version);
        
        // Adjust selection if needed
        if self.selected_baseline >= self.baselines.len() && !self.baselines.is_empty() {
            self.selected_baseline = self.baselines.len() - 1;
        }
        
        // TODO: Actually delete the baseline file
    }
    
    pub fn create_initial_baseline(&mut self) {
        // Check if an initial baseline already exists
        if self.baselines.iter().any(|b| b.is_initial) {
            // Show error popup - initial baseline already exists
            self.popup = Some(tui_components::Popup::error(
                "Initial Baseline Exists".to_string(),
                "An initial baseline already exists. Delete it first to create a new one.".to_string(),
            ));
            return;
        }
        
        // Default scan paths (from config.yaml or defaults)
        let scan_path = "/"; // Default to root
        let remap_to = "/";
        
        // Initialize progress state
        self.creating_baseline = true;
        self.creating_initial = true;
        self.baseline_progress.clear();
        self.baseline_completed.clear();
        self.baseline_files_processed = 0;
        self.baseline_estimated_total = None;
        self.baseline_start_time = Some(SystemTime::now());
        self.package_db_progress = None;
        self.baseline_phase = "scanning".to_string();
        
        // Create channel for progress updates
        let (tx, rx) = mpsc::channel();
        self.progress_rx = Some(rx);
        
        // Create cancel flag
        let cancel_flag = Arc::new(std::sync::atomic::AtomicBool::new(false));
        
        // Clone data needed for background thread
        let data_dir = self.data_dir.clone();
        let config = self.config.baseline.clone();
        let scan_path = scan_path.to_string();
        let remap_to = remap_to.to_string();
        
        // Spawn baseline creation in background thread
        std::thread::spawn(move || {
            // Create progress callback that sends updates through channel
            let tx_clone = tx.clone();
            let progress_callback = move |phase: &str, current: usize, status: &str| {
                // Send progress update
                let _ = tx_clone.send(ProgressUpdate::FilesProcessed { count: current });
                
                // Parse status to extract worker info if available
                // Format: "WorkerStarted: dir_name" or "worker_name: file_count files | current_path" or "Completed: dir_name"
                if status.starts_with("WorkerStarted:") {
                    if let Some(dir_name) = status.strip_prefix("WorkerStarted: ") {
                        let _ = tx_clone.send(ProgressUpdate::WorkerStarted {
                            name: dir_name.to_string(),
                        });
                    }
                } else if status.starts_with("Completed:") {
                    if let Some(dir_name) = status.strip_prefix("Completed: ") {
                        let _ = tx_clone.send(ProgressUpdate::WorkerCompleted {
                            name: dir_name.to_string(),
                            file_count: current,
                        });
                    }
                } else if !status.is_empty() {
                    // Try to parse worker progress from status
                    // Format: "worker_name: file_count files | current_path"
                    let parts: Vec<&str> = status.split(" | ").collect();
                    if parts.len() >= 2 {
                        let worker_part = parts[0];
                        let path_part = parts[1];
                        if let Some((name, count_str)) = worker_part.split_once(": ") {
                            if let Some(count) = count_str.split_whitespace().next().and_then(|s| s.parse::<usize>().ok()) {
                                let _ = tx_clone.send(ProgressUpdate::WorkerProgress {
                                    name: name.to_string(),
                                    file_count: count,
                                    current_path: path_part.to_string(),
                                });
                            }
                        }
                    }
                }
                
                // Update phase if changed
                if phase != "scanning" {
                    let _ = tx_clone.send(ProgressUpdate::PhaseChanged { phase: phase.to_string() });
                }
            };
            
            // Create the baseline
            let result = crate::baseline::create_initial_baseline(
                &scan_path,
                &remap_to,
                &data_dir,
                &config,
                cancel_flag,
                progress_callback,
            );
            
            // Send completion message
            match result {
                Ok(baseline) => {
                    let _ = tx.send(ProgressUpdate::BaselineCompleted {
                        success: true,
                        message: format!("Initial baseline created with {} files", baseline.file_count),
                    });
                }
                Err(e) => {
                    let _ = tx.send(ProgressUpdate::BaselineCompleted {
                        success: false,
                        message: format!("Failed to create baseline: {}", e),
                    });
                }
            }
        });
    }
    
    /// Process pending progress updates from the background thread
    /// This should be called from the main event loop
    pub fn process_progress_updates(&mut self) {
        // Take ownership of the receiver temporarily to avoid borrow issues
        let rx_opt = self.progress_rx.take();
        if let Some(rx) = rx_opt {
            let mut should_keep_rx = true;
            
            // Process all pending updates (non-blocking)
            while let Ok(update) = rx.try_recv() {
                match update {
                    ProgressUpdate::WorkerStarted { name } => {
                        // Worker started - add to progress list
                        self.baseline_progress.push((name, 0, String::new()));
                    }
                    ProgressUpdate::WorkerProgress { name, file_count, current_path } => {
                        // Update existing worker or add new one
                        if let Some(worker) = self.baseline_progress.iter_mut().find(|w| w.0 == name) {
                            worker.1 = file_count;
                            worker.2 = current_path;
                        } else {
                            self.baseline_progress.push((name, file_count, current_path));
                        }
                    }
                    ProgressUpdate::WorkerCompleted { name, file_count } => {
                        // Move from active to completed
                        self.baseline_progress.retain(|w| w.0 != name);
                        self.baseline_completed.push((name, file_count));
                    }
                    ProgressUpdate::FilesProcessed { count } => {
                        self.baseline_files_processed = count;
                    }
                    ProgressUpdate::PackageProgress { processed, total } => {
                        self.package_db_progress = Some((processed, total));
                    }
                    ProgressUpdate::PhaseChanged { phase } => {
                        self.baseline_phase = phase;
                    }
                    ProgressUpdate::BaselineCompleted { success, message } => {
                        // Reset progress state
                        self.creating_baseline = false;
                        self.creating_initial = false;
                        should_keep_rx = false; // Don't keep receiver after completion
                        
                        if success {
                            // Reload baselines list (or add the new one)
                            // For now, just show success popup
                            self.popup = Some(tui_components::Popup::info(
                                "Baseline Created".to_string(),
                                message,
                            ));
                        } else {
                            self.popup = Some(tui_components::Popup::error(
                                "Baseline Creation Failed".to_string(),
                                message,
                            ));
                        }
                    }
                }
            }
            
            // Put receiver back if we should keep it
            if should_keep_rx {
                self.progress_rx = Some(rx);
            }
        }
    }
    
    pub fn move_baseline_up(&mut self) {
        if self.selected_baseline > 0 {
            self.selected_baseline -= 1;
        }
    }
    
    pub fn move_baseline_down(&mut self) {
        if self.selected_baseline < self.baselines.len().saturating_sub(1) {
            self.selected_baseline += 1;
        }
    }

    pub fn switch_to_next_tab(&mut self) {
        self.current_view = match self.current_view {
            ViewMode::Dashboard => ViewMode::Changes,
            ViewMode::Changes => ViewMode::Baselines,
            ViewMode::Baselines => ViewMode::Dashboard,
        };
    }

    pub fn switch_to_previous_tab(&mut self) {
        self.current_view = match self.current_view {
            ViewMode::Dashboard => ViewMode::Baselines,
            ViewMode::Changes => ViewMode::Dashboard,
            ViewMode::Baselines => ViewMode::Changes,
        };
    }

    pub fn set_view(&mut self, view: ViewMode) {
        self.current_view = view;
    }

    pub fn get_tab_items(&self) -> Vec<(String, ViewMode)> {
        vec![
            ("DASHBOARD".to_string(), ViewMode::Dashboard),
            ("CHANGES".to_string(), ViewMode::Changes),
            ("BASELINES".to_string(), ViewMode::Baselines),
        ]
    }
}
