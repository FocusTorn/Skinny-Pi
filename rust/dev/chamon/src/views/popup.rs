// Popup/Modal rendering - uses shared component
use crate::app::App;
use tui_components::render_popup as render_popup_component;

pub fn render_popup(f: &mut ratatui::Frame, area: ratatui::layout::Rect, app: &App) {
    if let Some(popup) = &app.popup {
        render_popup_component(f, area, popup);
    }
}

