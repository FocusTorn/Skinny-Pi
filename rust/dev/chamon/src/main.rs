// Chamon TUI main entry point
use chamon_tui::App;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    Terminal,
};
use std::io;

fn main() -> io::Result<()> {
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // Create app
    let mut app = App::new();

    // Main event loop
    loop {
        // Process any pending progress updates from background threads
        app.process_progress_updates();
        
        terminal.draw(|f| {
            chamon_tui::ui::render(f, &mut app);
        })?;

        // Use non-blocking event reading with timeout to allow progress updates
        match crossterm::event::poll(std::time::Duration::from_millis(100)) {
            Ok(true) => {
                match event::read()? {
                    Event::Key(key) => {
                        chamon_tui::events::handle_event(Event::Key(key), &mut app);
                        if app.should_quit {
                            break;
                        }
                    }
                    _ => {}
                }
            }
            Ok(false) => {
                // No event available, continue loop to process progress updates
            }
            Err(_) => {
                // Error polling, continue anyway
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
