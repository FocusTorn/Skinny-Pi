// Chamon configuration
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub title: String,
    #[serde(default)]
    pub baseline: BaselineConfig,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            title: "CHAMON - File change Monitor".to_string(),
            baseline: BaselineConfig::default(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BaselineConfig {
    #[serde(default)]
    pub exclude_directories: Vec<String>,
    #[serde(default)]
    pub existence_only_directories: Vec<String>,
    #[serde(default)]
    pub existence_only_extensions: Vec<String>,
    #[serde(default = "default_content_size_limit")]
    pub content_size_limit: u64,
    #[serde(default = "default_exclusion_log")]
    pub exclusion_log: String,
}

fn default_content_size_limit() -> u64 {
    102400 // 100KB
}

fn default_exclusion_log() -> String {
    "data/baselines/size-exclusions.log".to_string()
}

impl Default for BaselineConfig {
    fn default() -> Self {
        Self {
            exclude_directories: vec![
                // Virtual filesystems (kernel interfaces)
                "/dev".to_string(),
                "/proc".to_string(),
                "/sys".to_string(),
                // Temporary/runtime data (cleared on reboot)
                "/run".to_string(),
                "/tmp".to_string(),
                "/srv".to_string(),
                // Constantly changing during operation
                "/var".to_string(),
                // 100% package-managed directories (never manually modified)
                "/usr/lib".to_string(),
                "/usr/include".to_string(),
                "/usr/src".to_string(),
                "/usr/share".to_string(),
                "/usr/libexec".to_string(),
                "/usr/bin".to_string(),
                "/usr/sbin".to_string(),
                "/usr/games".to_string(),
                // Package management directories (100% safe)
                "/var/lib/dpkg".to_string(),
                "/var/lib/apt".to_string(),
                "/var/cache/apt".to_string(),
                "/var/log/apt".to_string(),
                // Symlinks
                "/.cursor-server".to_string(),
                "/bin".to_string(),
                "/lib".to_string(),
                "/sbin".to_string(),
                "/.local".to_string(),
                // Root user home directory - exclude user-specific subdirectories
                // (project files in /root/_playground are tracked separately)
                "/root/.cache".to_string(),
                "/root/.cargo".to_string(),
                "/root/.cursor".to_string(),
                "/root/.cursor-server".to_string(),
                "/root/.oh-my-zsh".to_string(),
                "/root/.rustup".to_string(),
                "/root/.ssh".to_string(),
                "/root/.local".to_string(),
                // Mount points (external drives)
                "/media".to_string(),
                "/mnt".to_string(),
            ],
            existence_only_directories: vec![
                "/opt".to_string(),
                "/usr/local/bin".to_string(),
                "/usr/local/sbin".to_string(),
                "/usr/local/lib".to_string(),
            ],
            existence_only_extensions: vec![
                ".so".to_string(),
                ".a".to_string(),
                ".bin".to_string(),
                ".pyc".to_string(),
                ".o".to_string(),
                ".exe".to_string(),
                ".dll".to_string(),
                ".dylib".to_string(),
                ".so.*".to_string(),
            ],
            content_size_limit: default_content_size_limit(),
            exclusion_log: default_exclusion_log(),
        }
    }
}
