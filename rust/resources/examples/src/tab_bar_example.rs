// Tab Bar Component Example
// Standalone example showing the tab bar component output
// 
// Expected output:
//                        ╭───────────╮  
// ── DASHBOARD ─ CHANGES ─╯ BASELINES ╰──
//
// This shows the Tab style with BASELINES as the active tab

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
    let mut active_tab_index = 2; // Start with BASELINES active to show the example
    
    // Render loop
    loop {
        terminal.draw(|f| {
            let area = f.area();
            
            // Create a centered box to show the tab bar
            let chunks = Layout::default()
                .direction(ratatui::layout::Direction::Vertical)
                .constraints([
                    Constraint::Percentage(40),  // Top spacer
                    Constraint::Length(5),       // Tab bar box
                    Constraint::Percentage(40),  // Bottom spacer
                    Constraint::Length(3),       // Instructions
                ])
                .split(area);
            
            // Create a centered horizontal layout within the tab bar box
            let tab_box_chunks = Layout::default()
                .direction(ratatui::layout::Direction::Horizontal)
                .constraints([
                    Constraint::Percentage(20),  // Left spacer
                    Constraint::Percentage(60),  // Tab bar area
                    Constraint::Percentage(20),  // Right spacer
                ])
                .split(chunks[1]);
            
            // Tab bar container block
            let tab_bar_container = Rect {
                x: tab_box_chunks[1].x,
                y: chunks[1].y,
                width: tab_box_chunks[1].width,
                height: chunks[1].height,
            };
            
            let tab_bar_block = Block::default()
                .borders(Borders::ALL)
                .title(" Tab Bar Component (Tab Style) ");
            f.render_widget(tab_bar_block, tab_bar_container);
            
            // Inner area for tab bar (accounting for border)
            let tab_bar_area = Rect {
                x: tab_bar_container.x + 1,
                y: tab_bar_container.y + 1,
                width: tab_bar_container.width.saturating_sub(2),
                height: tab_bar_container.height.saturating_sub(2),
            };
            
            // Create tabs with DASHBOARD, CHANGES, BASELINES
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
            
            // Render Tab style (shows the decorative brackets and top line)
            let tab_bar = TabBar::new(
                tab_items,
                TabBarStyle::Tab,
                TabBarAlignment::Center,
            )
            .with_position(TabBarPosition::TopOf(tab_bar_area));
            tab_bar.render(f);
            
            // Instructions
            let active_tab_name = match active_tab_index {
                0 => "DASHBOARD",
                1 => "CHANGES",
                2 => "BASELINES",
                _ => "UNKNOWN",
            };
            let instructions = Paragraph::new(vec![
                Line::from("Press ↑/↓ or 1/2/3 to change active tab | Press 'q' to quit"),
                Line::from(format!("Active tab: {}", active_tab_name)),
            ])
            .block(Block::default().borders(Borders::ALL).title(" Controls "))
            .style(Style::default());
            f.render_widget(instructions, chunks[3]);
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

