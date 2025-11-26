// View modules for different TUI screens
pub mod dashboard;
pub mod changes;
pub mod baselines;
pub mod popup;

pub use dashboard::render_dashboard;
pub use changes::render_changes;
pub use baselines::render_baselines;
pub use popup::render_popup;

