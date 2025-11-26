// Changes view
use crate::app::App;
use tui_components::DimmingContext;
use ratatui::{
    layout::Rect,
    style::{Color, Style},
    widgets::{Block, Borders, Paragraph},
    Frame,
};

pub fn render_changes(f: &mut Frame, area: Rect, _app: &App, _dimming: &DimmingContext) {
    let block = Block::default()
        .borders(Borders::ALL)
        .title(" File Changes ")
        .border_style(Style::default().fg(Color::Yellow));

    let content = Paragraph::new("Changes view - TODO: Implement file changes list")
        .block(block);

    f.render_widget(content, area);
}

