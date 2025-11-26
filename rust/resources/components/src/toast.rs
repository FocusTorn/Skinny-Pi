// Toast notification component
use ratatui::{
    layout::Rect,
    style::{Color, Modifier, Style},
    widgets::{Clear, Paragraph},
    Frame,
};
use std::time::SystemTime;

#[derive(Debug, Clone)]
pub enum ToastType {
    Success,
    Error,
    Info,
}

#[derive(Debug, Clone)]
pub struct Toast {
    pub message: String,
    pub toast_type: ToastType,
    pub shown_at: SystemTime,  // MUST use SystemTime, not Instant
}

impl Toast {
    pub fn new(message: String, toast_type: ToastType) -> Self {
        Self {
            message,
            toast_type,
            shown_at: SystemTime::now(),
        }
    }

    pub fn success(message: String) -> Self {
        Self::new(message, ToastType::Success)
    }

    pub fn error(message: String) -> Self {
        Self::new(message, ToastType::Error)
    }

    pub fn info(message: String) -> Self {
        Self::new(message, ToastType::Info)
    }
}

/// Render toasts in bottom-right corner, stacked upward
pub fn render_toasts(f: &mut Frame, area: Rect, toasts: &[Toast]) {
    use crate::helpers::hex_color;
    
    if toasts.is_empty() {
        return;
    }

    // Calculate the maximum width of all toasts
    let mut max_width = 0usize;
    let mut toast_data: Vec<(String, Color, String)> = Vec::new();

    for toast in toasts {
        let (icon, fg_color) = match toast.toast_type {
            ToastType::Success => ("✓", Color::Green),
            ToastType::Error => ("✗", Color::Red),
            ToastType::Info => ("ℹ", Color::Cyan),
        };

        let content = format!("{} {}", icon, toast.message);
        max_width = max_width.max(content.len());
        toast_data.push((content, fg_color, icon.to_string()));
    }

    // Add 3 spaces total for padding (2 on left, 1 on right minimum)
    max_width += 3;

    // Position offsets: start 1 line lower (down), very close to right edge
    let y_start_offset = 1u16;
    let x_padding_from_edge = 0u16;

    // Start from the bottom, going up
    let mut y_offset = 0u16;

    for (content, fg_color, _) in toast_data.iter().rev() {
        // Left-pad content to match max width
        let content_len = content.len();
        let left_padding = max_width.saturating_sub(content_len).saturating_sub(1).max(2);

        let mut padded_text = format!("{}{} ", " ".repeat(left_padding), content);

        // Pad to exact width if needed
        while padded_text.len() < max_width {
            padded_text.push(' ');
        }
        if padded_text.len() > max_width {
            padded_text.truncate(max_width);
        }

        let toast_height = 1u16;

        // Position on bottom right
        let toast_area = Rect {
            x: area.width.saturating_sub(max_width as u16 + x_padding_from_edge),
            y: (area.y + y_start_offset).saturating_sub(y_offset + toast_height),
            width: max_width as u16,
            height: toast_height,
        };

        // Clear the area first
        f.render_widget(Clear, toast_area);

        // Render toast
        let toast_widget = Paragraph::new(padded_text)
            .style(Style::default()
                .fg(*fg_color)
                .bg(hex_color(0x0A0A0A))
                .add_modifier(Modifier::BOLD));

        f.render_widget(toast_widget, toast_area);

        y_offset += toast_height;
    }
}
