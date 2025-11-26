// Chamon UI rendering
use crate::app::{App, ViewMode};
use crate::views::{render_dashboard, render_changes, render_baselines, render_popup};
use ratatui::{
    layout::{Constraint, Layout, Rect},
    style::Style,
    text::Line,
    widgets::Paragraph,
    Frame,
};
use tui_components::{TabBar, TabBarItem, TabBarStyle, TabBarAlignment, TabBarPosition};
use tui_components::DimmingContext;

pub fn render(f: &mut Frame, app: &App) {
    let area = f.area();
    
    // Create dimming context once - this centralizes all dimming logic
    let dimming = DimmingContext::new(app.popup.is_some());
    
    // Layout: title bar (3 lines), content (with tab bar on border), status
    let chunks = Layout::default()
        .direction(ratatui::layout::Direction::Vertical)
        .constraints([
            Constraint::Length(3), // Title bar with borders
            Constraint::Min(0),    // Content (tab bar will be on its top border)
            Constraint::Length(1), // Status
        ])
        .split(area);

    // Title bar with borders - use dimming context
    let title_block = ratatui::widgets::Block::default()
        .borders(ratatui::widgets::Borders::ALL)
        .border_style(Style::default().fg(dimming.border_color(true)));
    
    let title_text = format!(" {}", app.config.title);
    let title = Paragraph::new(Line::from(title_text))
        .block(title_block)
        .style(Style::default()
            .fg(dimming.text_color(true))  // Use dimming context
            .add_modifier(ratatui::style::Modifier::BOLD))
        .alignment(ratatui::layout::Alignment::Center);
    f.render_widget(title, chunks[0]);

    // Content area - move down one line to accommodate tab bar and top decorative line
    let content_area = Rect {
        x: chunks[1].x,
        y: chunks[1].y + 1, // One line lower
        width: chunks[1].width,
        height: chunks[1].height.saturating_sub(1), // Reduce height by 1
    };

    // Content area - render based on current view (this will draw the border)
    match app.current_view {
        ViewMode::Dashboard => render_dashboard(f, content_area, app, &dimming),
        ViewMode::Changes => render_changes(f, content_area, app, &dimming),
        ViewMode::Baselines => render_baselines(f, content_area, app, &dimming),
    }

    // Tab bar - render on top of the content box's top border
    let tab_items: Vec<TabBarItem> = app
        .get_tab_items()
        .iter()
        .map(|(name, view)| TabBarItem {
            name: name.clone(),
            active: *view == app.current_view,
        })
        .collect();

    // Position tab bar on top of the content area's top border
    let tab_bar = TabBar::new(tab_items, TabBarStyle::Tab, TabBarAlignment::Center)
        .with_position(TabBarPosition::TopOf(content_area));

    tab_bar.render(f);

    // Status bar
    let status_text = if dimming.modal_visible {
        "Modal active - Use arrow keys to navigate, Enter to confirm, Esc to cancel"
    } else {
        "Status: Ready | Press PgUp/PgDn to switch tabs | 'q' to quit"
    };
    let status = Paragraph::new(Line::from(status_text))
        .style(Style::default().fg(dimming.text_color(false)));  // Use dimming context
    f.render_widget(status, chunks[2]); // chunks[2] is the status bar (3 constraints = 3 chunks: 0, 1, 2)

    // Render popup last (overlays everything)
    if app.popup.is_some() {
        render_popup(f, area, app);
    }
}
