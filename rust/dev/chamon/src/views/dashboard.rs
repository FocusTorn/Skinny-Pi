// Dashboard view
use crate::app::App;
use tui_components::DimmingContext;
use ratatui::{
    layout::Rect,
    style::{Color, Style},
    text::Line,
    widgets::{Block, Borders, Paragraph},
    Frame,
};

pub fn render_dashboard(f: &mut Frame, area: Rect, _app: &App, _dimming: &DimmingContext) {
    let block = Block::default()
        .borders(Borders::ALL)
        .title(" Dashboard ")
        .border_style(Style::default().fg(Color::Cyan));

    let content = Paragraph::new(Line::from("Dashboard view - Coming soon"))
        .block(block);

    f.render_widget(content, area);
}

