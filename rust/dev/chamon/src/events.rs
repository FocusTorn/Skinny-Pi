// Chamon event handling
use crate::app::App;
use crossterm::event::{Event, KeyCode, KeyEvent};

pub fn handle_event(event: Event, app: &mut App) -> bool {
    match event {
        Event::Key(key_event) => handle_key(key_event, app),
        _ => false,
    }
}

fn handle_key(key: KeyEvent, app: &mut App) -> bool {
    match (key.modifiers, key.code) {
        // Quit
        (_, KeyCode::Char('q')) | (_, KeyCode::Char('Q')) => {
            if app.popup.is_some() {
                app.popup_cancel();
                true
            } else {
                app.should_quit = true;
                true
            }
        }
        (_, KeyCode::Esc) => {
            if app.popup.is_some() {
                app.popup_cancel();
                true
            } else {
                app.should_quit = true;
                true
            }
        }

        // Tab navigation (PgUp/PgDn always work, with or without modifiers)
        (_modifiers, KeyCode::PageUp) => {
            // Modifiers can be used for future tab sets, but for now all PageUp/PageDown work
            app.switch_to_previous_tab();
            true
        }
        (_modifiers, KeyCode::PageDown) => {
            // Modifiers can be used for future tab sets, but for now all PageUp/PageDown work
            app.switch_to_next_tab();
            true
        }

        // Direct tab selection (1, 2, 3)
        (_, KeyCode::Char('1')) => {
            app.set_view(crate::app::ViewMode::Dashboard);
            true
        }
        (_, KeyCode::Char('2')) => {
            app.set_view(crate::app::ViewMode::Changes);
            true
        }
        (_, KeyCode::Char('3')) => {
            app.set_view(crate::app::ViewMode::Baselines);
            true
        }

        // Navigation within views
        (_, KeyCode::Up | KeyCode::Char('k')) => {
            if app.popup.is_some() {
                app.popup_move_left();
                true
            } else if app.current_view == crate::app::ViewMode::Baselines {
                app.move_baseline_up();
                true
            } else {
                false
            }
        }
        (_, KeyCode::Down | KeyCode::Char('j')) => {
            if app.popup.is_some() {
                app.popup_move_right();
                true
            } else if app.current_view == crate::app::ViewMode::Baselines {
                app.move_baseline_down();
                true
            } else {
                false
            }
        }
        (_, KeyCode::Left) => {
            if app.popup.is_some() {
                app.popup_move_left();
                true
            } else {
                false
            }
        }
        (_, KeyCode::Right) => {
            if app.popup.is_some() {
                app.popup_move_right();
                true
            } else {
                false
            }
        }

        // Baselines view actions
        (_, KeyCode::Char('n')) => {
            if app.popup.is_none() && app.current_view == crate::app::ViewMode::Baselines {
                // TODO: Create new baseline
                true
            } else {
                false
            }
        }
        (_, KeyCode::Char('i')) => {
            if app.popup.is_none() && app.current_view == crate::app::ViewMode::Baselines {
                app.create_initial_baseline();
                true
            } else {
                false
            }
        }
        (_, KeyCode::Char('c')) => {
            if app.popup.is_none() && app.current_view == crate::app::ViewMode::Baselines {
                // TODO: Compare to active
                true
            } else {
                false
            }
        }
        (_, KeyCode::Delete) => {
            if app.popup.is_none() && app.current_view == crate::app::ViewMode::Baselines {
                app.show_delete_confirmation();
                true
            } else {
                false
            }
        }

        // Popup actions
        (_, KeyCode::Enter) => {
            if app.popup.is_some() {
                app.popup_confirm();
                true
            } else {
                false
            }
        }

        _ => false,
    }
}
