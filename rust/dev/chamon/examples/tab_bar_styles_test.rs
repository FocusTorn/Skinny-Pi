// Tab Bar Styles Test
// Demonstrates both Tab and Text styles with DASHBOARD, CHANGES, and BASELINES tabs
use ratatui::{
    backend::CrosstermBackend,
    Terminal,
    layout::{Constraint, Layout, Rect},
    style::Style,
    text::Line,
    widgets::{Block, Borders, Paragraph},
};
use std::io;
use tui_components::{TabBar, TabBarItem, TabBarStyle, TabBarAlignment, TabBarPosition};
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;
    
    // State: which tab is active (0 = DASHBOARD, 1 = CHANGES, 2 = BASELINES)
    let mut active_tab_index = 0;
    
    // Render loop
    loop {
        terminal.draw(|f| {
            let area = f.area();
            
            // Create layout: top section with instructions, then two sections for each style
            let chunks = Layout::default()
                .direction(ratatui::layout::Direction::Vertical)
                .constraints([
                    Constraint::Length(5),  // Instructions
                    Constraint::Length(1),  // Spacer
                    Constraint::Length(5),  // Tab style section
                    Constraint::Length(1),  // Spacer
                    Constraint::Length(5),  // Text style section
                    Constraint::Min(0),     // Remaining space
                ])
                .split(area);
            
            // Instructions
            let active_tab_name = match active_tab_index {
                0 => "DASHBOARD",
                1 => "CHANGES",
                2 => "BASELINES",
                _ => "UNKNOWN",
            };
            let instructions = Paragraph::new(vec![
                Line::from("Tab Bar Styles Test - Press arrow keys (↑/↓) or number keys (1/2/3) to change active tab"),
                Line::from("Press 'q' or ESC to quit"),
                Line::from(""),
                Line::from(format!("Current active tab: {} (index: {})", active_tab_name, active_tab_index + 1)),
            ])
            .block(Block::default().borders(Borders::ALL).title(" Instructions "))
            .style(Style::default());
            f.render_widget(instructions, chunks[0]);
            
            // Tab Style Section
            let tab_style_area = chunks[2];
            let tab_style_block = Block::default()
                .borders(Borders::ALL)
                .title(" Tab Style (TabBarStyle::Tab) ");
            f.render_widget(tab_style_block, tab_style_area);
            
            // Inner area for tab bar
            let tab_style_inner = Rect {
                x: tab_style_area.x + 1,
                y: tab_style_area.y + 1,
                width: tab_style_area.width.saturating_sub(2),
                height: tab_style_area.height.saturating_sub(2),
            };
            
            // Create tabs with active tab based on index
            let tab_items: Vec<TabBarItem> = vec![
                TabBarItem {
                    name: "DASHBOARD".to_string(),
                    active: active_tab_index == 0,
                },
                TabBarItem {
                    name: "CHANGES".to_string(),
                    active: active_tab_index == 1,
                },
                TabBarItem {
                    name: "BASELINES".to_string(),
                    active: active_tab_index == 2,
                },
            ];
            
            // Render Tab style
            let tab_bar_tab_style = TabBar::new(
                tab_items.clone(),
                TabBarStyle::Tab,
                TabBarAlignment::Center,
            )
            .with_position(TabBarPosition::TopOf(tab_style_inner));
            tab_bar_tab_style.render(f);
            
            // Text Style Section
            let text_style_area = chunks[4];
            let text_style_block = Block::default()
                .borders(Borders::ALL)
                .title(" Text Style (TabBarStyle::Text) ");
            f.render_widget(text_style_block, text_style_area);
            
            // Inner area for tab bar
            let text_style_inner = Rect {
                x: text_style_area.x + 1,
                y: text_style_area.y + 1,
                width: text_style_area.width.saturating_sub(2),
                height: text_style_area.height.saturating_sub(2),
            };
            
            // Render Text style
            let tab_bar_text_style = TabBar::new(
                tab_items,
                TabBarStyle::Text,
                TabBarAlignment::Center,
            )
            .with_position(TabBarPosition::TopOf(text_style_inner));
            tab_bar_text_style.render(f);
        })?;
        
        // Handle keyboard input
        if let Event::Key(key) = event::read()? {
            match key.code {
                KeyCode::Char('q') | KeyCode::Esc => {
                    break;
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    // Move to previous tab
                    active_tab_index = if active_tab_index > 0 {
                        active_tab_index - 1
                    } else {
                        2 // Wrap to last tab
                    };
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    // Move to next tab
                    active_tab_index = (active_tab_index + 1) % 3;
                }
                KeyCode::Char('1') => {
                    active_tab_index = 0; // DASHBOARD
                }
                KeyCode::Char('2') => {
                    active_tab_index = 1; // CHANGES
                }
                KeyCode::Char('3') => {
                    active_tab_index = 2; // BASELINES
                }
                _ => {}
            }
        }
    }
    
    // Restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;
    
    Ok(())
}

