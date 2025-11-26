// Simple demo showing just the tab bar component
use ratatui::{
    backend::CrosstermBackend,
    Terminal,
    layout::Rect,
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
    
    // Render loop
    loop {
        terminal.draw(|f| {
            let area = f.area();
            // Position tab bar in the middle of the screen
            let tab_bar_rect = Rect {
                x: 0,
                y: area.height / 2,
                width: area.width,
                height: 1,
            };
            
            let tab_bar = TabBar::new(
                vec![
                    TabBarItem { name: "DASHBOARD".to_string(), active: false },
                    TabBarItem { name: "CHANGES".to_string(), active: false },
                    TabBarItem { name: "BASELINES".to_string(), active: true },
                ],
                TabBarStyle::Tab,
                TabBarAlignment::Center,
            ).with_position(TabBarPosition::TopOf(tab_bar_rect));
            
            tab_bar.render(f);
        })?;
        
        // Wait for key press to exit
        if let Event::Key(key) = event::read()? {
            if key.code == KeyCode::Char('q') || key.code == KeyCode::Esc {
                break;
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

