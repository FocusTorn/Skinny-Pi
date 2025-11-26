// Tab Bar Component
// A flexible tab bar component with multiple styling and positioning options

use ratatui::{
    layout::Rect,
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::Paragraph,
    Frame,
};

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TabBarStyle {
    /// Curved brackets around active tab: ╭─────╮
    Tab,
    /// Plain text with separators: ─ TAB ─
    Text,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TabBarAlignment {
    Left,
    Center,
    Right,
}

#[derive(Debug, Clone)]
pub enum TabBarPosition {
    /// Attach to top or bottom of a bounding box
    TopOf(Rect),
    BottomOf(Rect),
    /// Direct coordinates (x1, x2, y)
    Coords { x1: u16, x2: u16, y: u16 },
}

#[derive(Debug, Clone)]
pub struct TabBarItem {
    pub name: String,
    pub active: bool,
}

pub struct TabBar {
    pub items: Vec<TabBarItem>,
    pub style: TabBarStyle,
    pub alignment: TabBarAlignment,
    pub position: TabBarPosition,
}

impl TabBar {
    pub fn new(items: Vec<TabBarItem>, style: TabBarStyle, alignment: TabBarAlignment) -> Self {
        Self {
            items,
            style,
            alignment,
            position: TabBarPosition::Coords { x1: 0, x2: 0, y: 0 },
        }
    }

    pub fn with_position(mut self, position: TabBarPosition) -> Self {
        self.position = position;
        self
    }

    pub fn render(&self, f: &mut Frame) {
        let area = self.calculate_area(f.area());
        if area.width == 0 || area.height == 0 {
            return;
        }

        // Render the decorative line above the tab bar (only for Tab style)
        // Tab bar text is at rect.y (on the border), top decorative line is at rect.y - 1 (one line above)
        if self.style == TabBarStyle::Tab {
            if let Some(active_tab) = self.items.iter().find(|item| item.active) {
                // Top line is one line above the tab bar text
                // Tab bar is at area.y (which is rect.y), so top line is at area.y - 1 = rect.y - 1
                let top_line_area = Rect {
                    x: area.x,
                    y: area.y.saturating_sub(1), // One line above tab bar text
                    width: area.width,
                    height: 1,
                };
                
                if top_line_area.y < f.area().height && top_line_area.y >= 0 {
                    let top_line = self.build_top_line(area, active_tab);
                    let paragraph = Paragraph::new(top_line);
                    f.render_widget(paragraph, top_line_area);
                }
            }
        }

        // Use the estimated width, not the area width, to ensure all tabs are shown
        let estimated_width = self.estimate_width();
        let line = self.build_tab_line(estimated_width.max(area.width));
        let paragraph = Paragraph::new(line);
        f.render_widget(paragraph, area);
    }
    
    fn build_top_line(&self, tab_area: Rect, _active_tab: &TabBarItem) -> Line<'static> {
        let mut spans = Vec::new();
        
        // Find the position of the active tab within the tab bar
        let mut current_x = 0;
        let leading_sep = "── ";
        current_x += leading_sep.chars().count() as u16;
        
        let mut active_tab_start = 0;
        let mut active_tab_width = 0;
        
        // Calculate where the active tab starts (relative to tab bar start)
        for (idx, item) in self.items.iter().enumerate() {
            if idx > 0 {
                let is_before_active = item.active && self.style == TabBarStyle::Tab;
                let separator = if is_before_active {
                    " ─"
                } else {
                    " ─ "
                };
                current_x += separator.chars().count() as u16;
            }
            
            if item.active {
                active_tab_start = current_x;
                let text = format!("╯ {} ╰", item.name);
                active_tab_width = text.chars().count() as u16;
                break;
            } else {
                current_x += item.name.chars().count() as u16;
            }
        }
        
        // Build the top line: spaces before, ╭───╮ for active tab, spaces after
        // The line should align with the tab area
        let tab_area_start = tab_area.x;
        let active_tab_absolute_start = tab_area_start + active_tab_start;
        
        // Fill from start of tab area to start of active tab
        if active_tab_absolute_start > tab_area_start {
            let spaces_before = (active_tab_absolute_start - tab_area_start) as usize;
            if spaces_before > 0 {
                spans.push(Span::styled(" ".repeat(spaces_before), Style::default().fg(Color::White)));
            }
        }
        
        // Add the top bracket line for the active tab: ╭─────╮
        // The width should match the tab width (minus the brackets)
        let inner_width = active_tab_width.saturating_sub(2); // Subtract ╯ and ╰
        let bracket_line = if inner_width > 0 {
            format!("╭{}╮", "─".repeat(inner_width as usize))
        } else {
            "╭╮".to_string()
        };
        spans.push(Span::styled(bracket_line, Style::default().fg(Color::White)));
        
        // Fill the rest with spaces (if needed)
        let line_end = active_tab_absolute_start + active_tab_width;
        let tab_area_end = tab_area.x + tab_area.width;
        if line_end < tab_area_end {
            let spaces_after = (tab_area_end - line_end) as usize;
            if spaces_after > 0 {
                spans.push(Span::styled(" ".repeat(spaces_after), Style::default().fg(Color::White)));
            }
        }
        
        Line::from(spans)
    }

    fn calculate_area(&self, _frame_area: Rect) -> Rect {
        match &self.position {
            TabBarPosition::TopOf(rect) => {
                // Calculate tab bar width
                let tab_bar_width = self.estimate_width();
                
                // The rect passed in is the bounding box area (the Block's area)
                // The border characters are at the edges: left at rect.x, right at rect.x + rect.width - 1
                // For TopOf, we want to align on the border line itself (at rect.y)
                
                // Calculate x position based on alignment
                let x = match self.alignment {
                    TabBarAlignment::Left => {
                        // Align to left, starting after the left border character
                        rect.x + 1
                    }
                    TabBarAlignment::Center => {
                        // Center of the border line (accounting for border characters)
                        // The border line spans from rect.x to rect.x + rect.width - 1
                        // Center is at: rect.x + (rect.width - 1) / 2
                        // But we want the center of the visible area (between borders)
                        // Visible area: from rect.x + 1 to rect.x + rect.width - 2
                        // Center: rect.x + 1 + (rect.width - 3) / 2
                        // Simplified: rect.x + (rect.width + 1) / 2 - 1
                        let border_line_center = rect.x + rect.width / 2;
                        let tab_bar_center = tab_bar_width / 2;
                        border_line_center.saturating_sub(tab_bar_center)
                    }
                    TabBarAlignment::Right => {
                        // Align to right, ending before the right border character
                        let total_width = self.estimate_width();
                        (rect.x + rect.width).saturating_sub(total_width + 1)
                    }
                };
                
                // Ensure x doesn't go before the left border + 1 (to leave space for border char)
                let x = x.max(rect.x + 1);
                
                // Render on the top border (rect.y)
                // The top decorative line will be at rect.y - 1, tab bar text at rect.y
                // Calculate available width from x to just before the right border
                let right_edge = rect.x + rect.width - 1; // Right border character position
                let available_width = right_edge.saturating_sub(x) + 1;
                Rect {
                    x,
                    y: rect.y, // On the border
                    width: tab_bar_width.min(available_width),
                    height: 1,
                }
            }
            TabBarPosition::BottomOf(rect) => {
                let width = rect.width;
                let x = match self.alignment {
                    TabBarAlignment::Left => rect.x + 1,
                    TabBarAlignment::Center => {
                        let total_width = self.estimate_width();
                        rect.x + (rect.width.saturating_sub(total_width)) / 2
                    }
                    TabBarAlignment::Right => {
                        let total_width = self.estimate_width();
                        rect.x + rect.width.saturating_sub(total_width) - 1
                    }
                };
                Rect {
                    x,
                    y: rect.y + rect.height - 1,
                    width: width.min(self.estimate_width()),
                    height: 1,
                }
            }
            TabBarPosition::Coords { x1, x2, y } => Rect {
                x: *x1,
                y: *y,
                width: x2.saturating_sub(*x1),
                height: 1,
            },
        }
    }

    pub fn estimate_width(&self) -> u16 {
        // Calculate based on actual tab text and dividers (using character count)
        // Leading "── " = 3 chars
        let leading = "── ";
        let mut width = leading.chars().count() as u16;
        
        // Trailing "──" = 2 chars
        let trailing = "──";
        width += trailing.chars().count() as u16;
        
        for (idx, item) in self.items.iter().enumerate() {
            if idx > 0 {
                // Separator before each tab (except first)
                // Check if separator is before active tab (for Tab style)
                let is_before_active = item.active && self.style == TabBarStyle::Tab;
                let separator = if is_before_active {
                    " ─" // No space after, connects to ╯
                } else {
                    " ─ " // Space before and after
                };
                width += separator.chars().count() as u16;
            }
            
            // Tab text width (using character count)
            match self.style {
                TabBarStyle::Tab => {
                    if item.active {
                        // Active tab: "╯ BASELINES ╰"
                        let text = format!("╯ {} ╰", item.name);
                        width += text.chars().count() as u16;
                    } else {
                        // Inactive tab: just the name
                        width += item.name.chars().count() as u16;
                    }
                }
                TabBarStyle::Text => {
                    // Plain text: just the name
                    width += item.name.chars().count() as u16;
                }
            }
        }
        width
    }

    pub fn build_tab_line(&self, max_width: u16) -> Line<'static> {
        let mut spans = Vec::new();
        let mut current_width = 0;

        // Start with leading separator (with space after)
        let leading_sep = "── ";
        spans.push(Span::styled(leading_sep, Style::default().fg(Color::White)));
        current_width += leading_sep.chars().count() as u16;

        // Add tabs with separators - ensure we show all tabs
        for (idx, item) in self.items.iter().enumerate() {
            if idx > 0 {
                // Add separator before each tab (except first)
                // Check if this is the separator before the active tab
                let is_before_active = item.active;
                let separator = if is_before_active && self.style == TabBarStyle::Tab {
                    " ─" // No space after, will connect to ╯
                } else {
                    " ─ " // Space before and after
                };
                let sep_width = separator.chars().count() as u16; // Use char count, not byte length
                
                if current_width + sep_width <= max_width {
                    spans.push(Span::styled(separator, Style::default().fg(Color::White)));
                    current_width += sep_width;
                } else {
                    // If we can't fit the separator, we can't fit the tab either
                    break;
                }
            }

            let (tab_text, tab_width) = match self.style {
                TabBarStyle::Tab => {
                    if item.active {
                        // Active tab with curved brackets: ╯ BASELINES ╰
                        let text = format!("╯ {} ╰", item.name);
                        let width = text.chars().count() as u16; // Use char count, not byte length
                        (text, width)
                    } else {
                        // Inactive tab: plain text
                        let width = item.name.chars().count() as u16;
                        (item.name.clone(), width)
                    }
                }
                TabBarStyle::Text => {
                    // Plain text style
                    let width = item.name.chars().count() as u16;
                    (item.name.clone(), width)
                }
            };

            // Check if we can fit this tab
            // We only need to fit the tab itself - trailing separator is optional
            if current_width + tab_width > max_width {
                break; // Can't fit this tab
            }

            let style = if item.active {
                Style::default()
                    .fg(Color::White)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(Color::White)
            };

            spans.push(Span::styled(tab_text, style));
            current_width += tab_width;
        }

        // Add trailing separator if there's space (at least 2 chars needed)
        // Only add if we have at least 2 characters of space remaining
        if max_width >= current_width + 2 {
            spans.push(Span::styled("──", Style::default().fg(Color::White)));
        }

        Line::from(spans)
    }
}

