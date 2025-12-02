# Component Examples

Standalone examples demonstrating individual TUI components. These examples are separate from any main TUI application and can be run independently.

## Tab Bar Example

Shows the tab bar component with the Tab style, displaying DASHBOARD, CHANGES, and BASELINES tabs.

### Expected Output

With BASELINES as the active tab:
```
                        ╭───────────╮  
── DASHBOARD ─ CHANGES ─╯ BASELINES ╰──
```

### Running

```bash
cd /root/_playground/rust
cargo run --bin tab-bar-example --package component-examples
```

### Controls

- **↑/↓ or k/j**: Cycle through tabs
- **1/2/3**: Jump directly to DASHBOARD/CHANGES/BASELINES
- **q or ESC**: Quit

## Adding More Examples

To add a new component example:

1. Create a new binary in `src/` (e.g., `src/my_component_example.rs`)
2. Add a `[[bin]]` entry to `Cargo.toml`:
   ```toml
   [[bin]]
   name = "my-component-example"
   path = "src/my_component_example.rs"
   ```
3. Build and run:
   ```bash
   cargo run --bin my-component-example --package component-examples
   ```

