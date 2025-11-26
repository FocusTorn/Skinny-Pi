// Debug test to see what's happening with tab bar width
use tui_components::{TabBar, TabBarItem, TabBarStyle, TabBarAlignment};

fn main() {
    let tab_items = vec![
        TabBarItem { name: "DASHBOARD".to_string(), active: false },
        TabBarItem { name: "CHANGES".to_string(), active: false },
        TabBarItem { name: "BASELINES".to_string(), active: true },
    ];
    
    let tab_bar = TabBar::new(tab_items, TabBarStyle::Tab, TabBarAlignment::Center);
    let width = tab_bar.estimate_width();
    
    println!("Estimated width: {}", width);
    println!();
    println!("Manual calculation:");
    println!("  Leading '── ' = 3");
    println!("  DASHBOARD = 9");
    println!("  ' ─ ' = 3");
    println!("  CHANGES = 7");
    println!("  ' ─' (before active) = 2");
    println!("  '╯ BASELINES ╰' = 13");
    println!("  Trailing '──' = 2");
    println!("  Total: 3 + 9 + 3 + 7 + 2 + 13 + 2 = {}", 3 + 9 + 3 + 7 + 2 + 13 + 2);
    println!();
    
    // Test with exact width
    println!("Testing with width {}:", width);
    let line = tab_bar.build_tab_line(width);
    println!("Number of spans: {}", line.spans.len());
    let mut total = 0;
    for (i, span) in line.spans.iter().enumerate() {
        let len = span.content.chars().count();
        total += len;
        println!("  [{}] '{}' (char count: {}, byte len: {})", i, span.content, len, span.content.len());
    }
    println!("Total char count: {}", total);
    println!();
    
    // Print the actual output
    print!("Actual output: ");
    for span in &line.spans {
        print!("{}", span.content);
    }
    println!();
    println!();
    
    // Test with width + 1 to see if it helps
    println!("Testing with width {}:", width + 1);
    let line2 = tab_bar.build_tab_line(width + 1);
    print!("Output: ");
    for span in &line2.spans {
        print!("{}", span.content);
    }
    println!();
}

