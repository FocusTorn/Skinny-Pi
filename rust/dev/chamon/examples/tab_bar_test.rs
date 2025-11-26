// Simple test that prints the tab bar output
use tui_components::{TabBar, TabBarItem, TabBarStyle, TabBarAlignment};

fn main() {
    // Create tab items - BASELINES is active
    let tab_items = vec![
        TabBarItem {
            name: "DASHBOARD".to_string(),
            active: false,
        },
        TabBarItem {
            name: "CHANGES".to_string(),
            active: false,
        },
        TabBarItem {
            name: "BASELINES".to_string(),
            active: true, // Active tab
        },
    ];
    
    // Create tab bar
    let tab_bar = TabBar::new(tab_items, TabBarStyle::Tab, TabBarAlignment::Center);
    
    // Calculate the width needed
    let width = tab_bar.estimate_width();
    println!("Estimated width: {}", width);
    println!("Expected width: 40");
    println!();
    
    // Build the tab line with the exact calculated width
    println!("Building with width: {}", width);
    let line = tab_bar.build_tab_line(width);
    
    // Print the output
    println!("Tab bar output (width {}):", width);
    let mut total_len = 0;
    for span in &line.spans {
        print!("{}", span.content);
        total_len += span.content.len();
    }
    println!();
    println!("Total length: {}", total_len);
    println!();
    println!("Expected: ── DASHBOARD ─ CHANGES ─╯ BASELINES ╰──");
    println!("Expected length: 39");
    
    // Also test with a very wide width to see if all tabs show
    println!("\nWith wide width (200):");
    let line_wide = tab_bar.build_tab_line(200);
    for span in line_wide.spans {
        print!("{}", span.content);
    }
    println!();
}

