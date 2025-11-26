// Baselines view
use crate::app::App;
use tui_components::DimmingContext;
use ratatui::{
    layout::{Constraint, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, Paragraph},
    Frame,
};

pub fn render_baselines(f: &mut Frame, area: Rect, app: &App, dimming: &DimmingContext) {
    // Outer border around entire content area
    let outer_block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(dimming.border_color(true)));
    
    // Render outer border
    f.render_widget(outer_block, area);
    
    // Inner area (accounting for border)
    let inner_area = Rect {
        x: area.x + 1,
        y: area.y + 1,
        width: area.width.saturating_sub(2),
        height: area.height.saturating_sub(2),
    };
    
    // Layout: main content area and bindings box at bottom
    let main_chunks = Layout::default()
        .direction(ratatui::layout::Direction::Vertical)
        .constraints([
            Constraint::Min(0),        // Main content (two columns)
            Constraint::Length(3),     // Bindings box
        ])
        .split(inner_area);

    // Two-column layout: Entries (left) and Display (right)
    let columns = Layout::default()
        .direction(ratatui::layout::Direction::Horizontal)
        .constraints([
            Constraint::Percentage(50), // Entries panel
            Constraint::Percentage(50), // Display panel
        ])
        .split(main_chunks[0]);

    // Left column: Entries (baseline list)
    render_baseline_list(f, columns[0], app, dimming);
    
    // Right column: Display panel
    render_display_panel(f, columns[1], app, dimming);
    
    // Bindings box at bottom
    render_bindings_box(f, main_chunks[1], dimming);
}

fn render_baseline_list(f: &mut Frame, area: Rect, app: &App, dimming: &DimmingContext) {
    // Use dimming context for border color
    // Title format: "─ Entries ─" to match design
    let block = Block::default()
        .borders(Borders::ALL)
        .title("─ Entries ─")
        .title_alignment(ratatui::layout::Alignment::Left)
        .border_style(Style::default().fg(dimming.border_color(true)));

    let items: Vec<ListItem> = app
        .baselines
        .iter()
        .map(|baseline| {
            let mut spans = Vec::new();
            
            // Active indicator - use dimming context
            // Format: " → " (with spaces) to match design
            if baseline.is_active {
                spans.push(Span::styled(
                    " → ",
                    Style::default().fg(dimming.dim_color(Color::Green)).add_modifier(Modifier::BOLD),
                ));
            } else {
                spans.push(Span::raw("   "));
            }
            
            // Version - use dimming context
            spans.push(Span::styled(
                baseline.version.clone(),
                Style::default().fg(dimming.text_color(true)),
            ));
            
            // File count with proper spacing
            let count_text = if baseline.is_initial {
                format!("   ({} files)", baseline.file_count)
            } else {
                format!("   ({} changes)", baseline.file_count)
            };
            
            spans.push(Span::styled(
                count_text,
                Style::default().fg(dimming.dim_color(Color::DarkGray)),
            ));
            
            let line = Line::from(spans);
            ListItem::new(line)
        })
        .collect();

    // Use dimming context for selection style
    let highlight_style = dimming.selection_style(true);

    let list = List::new(items)
        .block(block)
        .highlight_style(highlight_style)
        .highlight_symbol(""); // No symbol needed - highlight background shows selection

    // Create a stateful list state
    use ratatui::widgets::ListState;
    let mut state = ListState::default();
    state.select(Some(app.selected_baseline));
    
    f.render_stateful_widget(list, area, &mut state);
}

fn render_display_panel(f: &mut Frame, area: Rect, app: &App, dimming: &DimmingContext) {
    // If creating baseline, show progress view
    if app.creating_baseline {
        render_progress_view(f, area, app, dimming);
    } else {
        // Default placeholder content
        let block = Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(dimming.border_color(true)));

        let content_lines = vec![
            Line::from(""),
            Line::from(vec![
                Span::styled(
                    "     Display of:",
                    Style::default().fg(dimming.text_color(false)),
                ),
            ]),
            Line::from(vec![
                Span::styled(
                    "     Baseline creation Progress",
                    Style::default().fg(dimming.text_color(false)),
                ),
            ]),
            Line::from(vec![
                Span::styled(
                    "     initial creation progress",
                    Style::default().fg(dimming.text_color(false)),
                ),
            ]),
            Line::from(vec![
                Span::styled(
                    "     highlevel view of contents",
                    Style::default().fg(dimming.text_color(false)),
                ),
            ]),
            Line::from(""),
        ];

        let paragraph = Paragraph::new(content_lines)
            .block(block)
            .alignment(ratatui::layout::Alignment::Left);

        f.render_widget(paragraph, area);
    }
}

fn render_progress_view(f: &mut Frame, area: Rect, app: &App, dimming: &DimmingContext) {
    use ratatui::layout::Direction;
    
    // Calculate layout: Progress/Package section, Active Workers, Completed Directories
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(8),  // Progress Overview or Package Database
            Constraint::Min(5),    // Active Workers (flexible)
            Constraint::Min(5),    // Completed Directories (flexible)
        ])
        .split(area);
    
    // Progress Overview or Package Database
    if app.baseline_phase == "packaging" {
        render_package_database(f, chunks[0], app, dimming);
    } else {
        render_progress_overview(f, chunks[0], app, dimming);
    }
    
    // Active Workers
    render_active_workers(f, chunks[1], app, dimming);
    
    // Completed Directories
    render_completed_directories(f, chunks[2], app, dimming);
}

fn render_progress_overview(f: &mut Frame, area: Rect, app: &App, dimming: &DimmingContext) {
    let block = Block::default()
        .borders(Borders::ALL)
        .title(" Progress Overview ")
        .border_style(Style::default().fg(dimming.border_color(true)));
    
    let mut lines = Vec::new();
    
    // Files processed
    let files_text = if let Some(total) = app.baseline_estimated_total {
        format!("Files Processed: {} / ~{} (estimated)", app.baseline_files_processed, total)
    } else {
        format!("Files Processed: {}", app.baseline_files_processed)
    };
    lines.push(Line::from(vec![
        Span::styled(files_text, Style::default().fg(dimming.text_color(true))),
    ]));
    
    // Progress bar
    let progress_percent = if let Some(total) = app.baseline_estimated_total {
        if total > 0 {
            (app.baseline_files_processed as f64 / total as f64 * 100.0) as u32
        } else {
            0
        }
    } else {
        0
    };
    
    let bar_width: usize = 50;
    let filled = (bar_width as f64 * progress_percent as f64 / 100.0) as usize;
    let bar = format!("{}{} {}%", 
        "█".repeat(filled),
        "░".repeat(bar_width.saturating_sub(filled)),
        progress_percent
    );
    lines.push(Line::from(vec![
        Span::styled(bar, Style::default().fg(dimming.text_color(true))),
    ]));
    
    // Elapsed and estimated remaining time
    if let Some(start_time) = app.baseline_start_time {
        let elapsed = start_time.elapsed().unwrap_or_default();
        let elapsed_secs = elapsed.as_secs();
        let elapsed_min = elapsed_secs / 60;
        let elapsed_sec = elapsed_secs % 60;
        
        let remaining_text = if let Some(total) = app.baseline_estimated_total {
            if app.baseline_files_processed > 0 && total > app.baseline_files_processed {
                let rate = app.baseline_files_processed as f64 / elapsed_secs.max(1) as f64;
                let remaining = ((total - app.baseline_files_processed) as f64 / rate) as u64;
                let remaining_min = remaining / 60;
                let remaining_sec = remaining % 60;
                format!("Elapsed: {}m {}s | Estimated Remaining: {}m {}s", 
                    elapsed_min, elapsed_sec, remaining_min, remaining_sec)
            } else {
                format!("Elapsed: {}m {}s", elapsed_min, elapsed_sec)
            }
        } else {
            format!("Elapsed: {}m {}s", elapsed_min, elapsed_sec)
        };
        
        lines.push(Line::from(vec![
            Span::styled(remaining_text, Style::default().fg(dimming.text_color(false))),
        ]));
    }
    
    lines.push(Line::from(""));
    
    // Active workers count
    let workers_text = format!("Active Workers: {} threads", app.baseline_progress.len());
    lines.push(Line::from(vec![
        Span::styled(workers_text, Style::default().fg(dimming.text_color(false))),
    ]));
    
    let paragraph = Paragraph::new(lines)
        .block(block)
        .alignment(ratatui::layout::Alignment::Left);
    
    f.render_widget(paragraph, area);
}

fn render_package_database(f: &mut Frame, area: Rect, app: &App, dimming: &DimmingContext) {
    let block = Block::default()
        .borders(Borders::ALL)
        .title(" Package Database ")
        .border_style(Style::default().fg(dimming.border_color(true)));
    
    let mut lines = Vec::new();
    
    lines.push(Line::from(vec![
        Span::styled(
            "Building package file database...",
            Style::default().fg(dimming.text_color(true)),
        ),
    ]));
    
    if let Some((processed, total)) = app.package_db_progress {
        let progress_text = format!("Processed: {} / {} packages", processed, total);
        lines.push(Line::from(vec![
            Span::styled(progress_text, Style::default().fg(dimming.text_color(true))),
        ]));
        
        // Progress bar
        let progress_percent = if total > 0 {
            (processed as f64 / total as f64 * 100.0) as u32
        } else {
            0
        };
        
        let bar_width: usize = 50;
        let filled = (bar_width as f64 * progress_percent as f64 / 100.0) as usize;
        let bar = format!("{}{} {}%", 
            "█".repeat(filled),
            "░".repeat(bar_width.saturating_sub(filled)),
            progress_percent
        );
        lines.push(Line::from(vec![
            Span::styled(bar, Style::default().fg(dimming.text_color(true))),
        ]));
    }
    
    let paragraph = Paragraph::new(lines)
        .block(block)
        .alignment(ratatui::layout::Alignment::Left);
    
    f.render_widget(paragraph, area);
}

fn render_active_workers(f: &mut Frame, area: Rect, app: &App, dimming: &DimmingContext) {
    let block = Block::default()
        .borders(Borders::ALL)
        .title(" Active Workers ")
        .border_style(Style::default().fg(dimming.border_color(true)));
    
    let items: Vec<ListItem> = if app.baseline_progress.is_empty() {
        vec![ListItem::new("No active workers")]
    } else {
        // Spinner characters for visual feedback
        let spinners = ["⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"];
        
        app.baseline_progress
            .iter()
            .enumerate()
            .map(|(idx, (worker_name, file_count, current_path))| {
                let spinner = spinners[idx % spinners.len()];
                
                // Truncate path if too long
                let max_path_len = 30;
                let display_path = if current_path.len() > max_path_len {
                    format!("...{}", &current_path[current_path.len().saturating_sub(max_path_len - 3)..])
                } else {
                    current_path.clone()
                };
                
                ListItem::new(Line::from(vec![
                    Span::styled(spinner, Style::default().fg(Color::Yellow)),
                    Span::raw(" "),
                    Span::styled(worker_name, Style::default().fg(dimming.text_color(true)).add_modifier(Modifier::BOLD)),
                    Span::raw(format!(" {:>8} files | Scanning: ", file_count)),
                    Span::styled(display_path, Style::default().fg(dimming.text_color(false)).add_modifier(Modifier::DIM)),
                ]))
            })
            .collect()
    };
    
    let list = List::new(items).block(block);
    f.render_widget(list, area);
}

fn render_completed_directories(f: &mut Frame, area: Rect, app: &App, dimming: &DimmingContext) {
    let block = Block::default()
        .borders(Borders::ALL)
        .title(format!(" Completed Directories ({}) ", app.baseline_completed.len()))
        .border_style(Style::default().fg(dimming.border_color(true)));
    
    let items: Vec<ListItem> = if app.baseline_completed.is_empty() {
        vec![ListItem::new("No directories completed yet")]
    } else {
        app.baseline_completed
            .iter()
            .map(|(dir_name, file_count)| {
                ListItem::new(Line::from(vec![
                    Span::styled("  ✓ ", Style::default().fg(Color::Green)),
                    Span::styled(dir_name.clone(), Style::default().fg(dimming.text_color(true))),
                    Span::raw(format!(" {:>8} files", file_count)),
                ]))
            })
            .collect()
    };
    
    let list = List::new(items).block(block);
    f.render_widget(list, area);
}

fn render_bindings_box(f: &mut Frame, area: Rect, dimming: &DimmingContext) {
    // Bindings box showing keyboard shortcuts
    let block = Block::default()
        .borders(Borders::ALL)
        .title("─ Bindings ─")
        .title_alignment(ratatui::layout::Alignment::Left)
        .border_style(Style::default().fg(dimming.border_color(true)));

    // Bindings text: [n] New Baseline | [i] Create Initial Baseline | [c] Compare to active | [del] Delete selected
    let bindings_text = vec![
        Line::from(vec![
            Span::styled("[n] ", Style::default().fg(dimming.text_color(true)).add_modifier(Modifier::BOLD)),
            Span::styled("New Baseline", Style::default().fg(dimming.text_color(false))),
            Span::styled(" | ", Style::default().fg(dimming.text_color(false))),
            Span::styled("[i] ", Style::default().fg(dimming.text_color(true)).add_modifier(Modifier::BOLD)),
            Span::styled("Create Initial Baseline", Style::default().fg(dimming.text_color(false))),
            Span::styled(" | ", Style::default().fg(dimming.text_color(false))),
            Span::styled("[c] ", Style::default().fg(dimming.text_color(true)).add_modifier(Modifier::BOLD)),
            Span::styled("Compare to active", Style::default().fg(dimming.text_color(false))),
            Span::styled(" | ", Style::default().fg(dimming.text_color(false))),
            Span::styled("[del] ", Style::default().fg(dimming.text_color(true)).add_modifier(Modifier::BOLD)),
            Span::styled("Delete selected", Style::default().fg(dimming.text_color(false))),
        ]),
    ];

    let paragraph = Paragraph::new(bindings_text)
        .block(block)
        .alignment(ratatui::layout::Alignment::Left);

    f.render_widget(paragraph, area);
}

// Action buttons and comparison results removed from this view
// They may be moved to a different location or shown in the display panel later
