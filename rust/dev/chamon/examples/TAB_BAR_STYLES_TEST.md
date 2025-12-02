# Tab Bar Styles Test

## Description

This test script demonstrates both tab bar styles (Tab and Text) using the three tabs:
- DASHBOARD
- CHANGES
- BASELINES

The script displays both styles side-by-side so you can compare the visual differences.

## Running the Test

```bash
cd /root/_playground/rust
cargo run --example tab_bar_styles_test --package chamon-tui
```

## Controls

- **↑/↓ or k/j**: Cycle through tabs (change which tab is active)
- **1/2/3**: Jump directly to DASHBOARD/CHANGES/BASELINES
- **q or ESC**: Quit the test

## What It Shows

1. **Tab Style** (`TabBarStyle::Tab`):
   - Active tab shows with curved brackets: `╯ TAB_NAME ╰`
   - Decorative top line above active tab: `╭─────╮`
   - Separators between tabs: `── TAB ──`

2. **Text Style** (`TabBarStyle::Text`):
   - Plain text with separators
   - Active tab is bold
   - Format: `── TAB ──`

## Visual Layout

The test shows:
- Instructions panel at the top
- Tab Style section (with decorative brackets)
- Text Style section (plain text)
- Both sections update together when you change the active tab

