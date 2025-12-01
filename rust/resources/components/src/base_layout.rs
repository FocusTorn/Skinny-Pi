// Base layout component for TUI applications
// Provides title header, tab bar, status bar, and global bindings
use crate::helpers::DimmingContext;
use crate::tab_bar::{TabBar, TabBarItem, TabBarStyle, TabBarAlignment, TabBarPosition};
use ratatui::{
    layout::{Constraint, Layout, Rect},
    style::{Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph},
    Frame,
};

/// Configuration for the base layout UI elements
#[derive(Debug, Clone)]
pub struct BaseLayoutConfig {
    pub title: String,
    pub tabs: Vec<TabConfig>,
    pub global_bindings: Vec<BindingConfig>,
    pub status_bar: StatusBarConfig,
}

/// Configuration for a tab
#[derive(Debug, Clone)]
pub struct TabConfig {
    pub name: String,
    pub id: String, // Unique identifier for the tab
}

/// Configuration for a keyboard binding display
#[derive(Debug, Clone)]
pub struct BindingConfig {
    pub key: String,        // e.g., "[n]", "[Ctrl+C]"
    pub description: String, // e.g., "New Baseline"
}

/// Configuration for the status bar
#[derive(Debug, Clone)]
pub struct StatusBarConfig {
    pub default_text: String,
    pub modal_text: Option<String>, // Text to show when modal is active
}

impl Default for StatusBarConfig {
    fn default() -> Self {
        Self {
            default_text: "Status: Ready | Press PgUp/PgDn to switch tabs | 'q' to quit".to_string(),
            modal_text: Some("Modal active - Use arrow keys to navigate, Enter to confirm, Esc to cancel".to_string()),
        }
    }
}

/// Result of rendering the base layout
/// Provides the content area where application-specific content should be rendered
#[derive(Debug, Clone)]
pub struct BaseLayoutResult {
    pub content_area: Rect, // The area where content panels should be rendered
}

/// Base layout component that renders the standard TUI frame structure
pub struct BaseLayout<'a> {
    config: &'a BaseLayoutConfig,
    active_tab_id: Option<&'a str>,
    dimming: &'a DimmingContext,
}

impl<'a> BaseLayout<'a> {
    pub fn new(
        config: &'a BaseLayoutConfig,
        active_tab_id: Option<&'a str>,
        dimming: &'a DimmingContext,
    ) -> Self {
        Self {
            config,
            active_tab_id,
            dimming,
        }
    }

    /// Render the base layout and return the content area
    pub fn render(&self, f: &mut Frame, area: Rect) -> BaseLayoutResult {
        // Layout: title bar (3 lines), content (with tab bar on border), status
        let chunks = Layout::default()
            .direction(ratatui::layout::Direction::Vertical)
            .constraints([
                Constraint::Length(3), // Title bar with borders
                Constraint::Min(0),    // Content (tab bar will be on its top border)
                Constraint::Length(1), // Status
            ])
            .split(area);

        // Render title header
        self.render_title(f, chunks[0]);

        // Calculate content area - move down one line to accommodate tab bar
        let content_area = Rect {
            x: chunks[1].x,
            y: chunks[1].y + 1, // One line lower
            width: chunks[1].width,
            height: chunks[1].height.saturating_sub(1), // Reduce height by 1
        };

        // Render tab bar on top of content area's top border
        self.render_tab_bar(f, content_area);

        // Render status bar
        self.render_status_bar(f, chunks[2]);

        BaseLayoutResult { content_area }
    }

    /// Render the title header with borders
    fn render_title(&self, f: &mut Frame, area: Rect) {
        let title_block = Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(self.dimming.border_color(true)));
        
        let title_text = format!(" {}", self.config.title);
        let title = Paragraph::new(Line::from(title_text))
            .block(title_block)
            .style(Style::default()
                .fg(self.dimming.text_color(true))
                .add_modifier(Modifier::BOLD))
            .alignment(ratatui::layout::Alignment::Center);
        f.render_widget(title, area);
    }

    /// Render the tab bar
    fn render_tab_bar(&self, f: &mut Frame, content_area: Rect) {
        let tab_items: Vec<TabBarItem> = self
            .config
            .tabs
            .iter()
            .map(|tab| TabBarItem {
                name: tab.name.clone(),
                active: self.active_tab_id.map_or(false, |id| id == tab.id),
            })
            .collect();

        // Position tab bar on top of the content area's top border
        let tab_bar = TabBar::new(tab_items, TabBarStyle::Tab, TabBarAlignment::Center)
            .with_position(TabBarPosition::TopOf(content_area));

        tab_bar.render(f);
    }

    /// Render the status bar
    fn render_status_bar(&self, f: &mut Frame, area: Rect) {
        let status_text = if self.dimming.modal_visible {
            self.config.status_bar.modal_text.as_deref()
                .unwrap_or(&self.config.status_bar.default_text)
        } else {
            &self.config.status_bar.default_text
        };

        let status = Paragraph::new(Line::from(status_text))
            .style(Style::default().fg(self.dimming.text_color(false)));
        f.render_widget(status, area);
    }
}

/// Render global bindings box
/// This can be called from within content views to show global keyboard shortcuts
pub fn render_global_bindings(
    f: &mut Frame,
    area: Rect,
    bindings: &[BindingConfig],
    dimming: &DimmingContext,
) {
    let block = Block::default()
        .borders(Borders::ALL)
        .title("─ Bindings ─")
        .title_alignment(ratatui::layout::Alignment::Left)
        .border_style(Style::default().fg(dimming.border_color(true)));

    // Build bindings text line
    let mut spans = Vec::new();
    for (idx, binding) in bindings.iter().enumerate() {
        if idx > 0 {
            spans.push(Span::styled(" | ", Style::default().fg(dimming.text_color(false))));
        }
        spans.push(Span::styled(
            binding.key.clone(),
            Style::default()
                .fg(dimming.text_color(true))
                .add_modifier(Modifier::BOLD),
        ));
        spans.push(Span::styled(
            format!(" {}", binding.description),
            Style::default().fg(dimming.text_color(false)),
        ));
    }

    let bindings_text = vec![Line::from(spans)];
    let paragraph = Paragraph::new(bindings_text)
        .block(block)
        .alignment(ratatui::layout::Alignment::Left);

    f.render_widget(paragraph, area);
}

