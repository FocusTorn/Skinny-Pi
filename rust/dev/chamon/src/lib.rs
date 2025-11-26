// Chamon library
// Core functionality for chamon TUI

pub mod app;
pub mod baseline;
pub mod config;
pub mod events;
pub mod ui;
pub mod views;

pub use app::{App, ViewMode};
pub use baseline::{Baseline, create_initial_baseline};
pub use config::Config;
