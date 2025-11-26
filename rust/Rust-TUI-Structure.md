# Rust TUI Development Structure

## Overview

This directory structure is designed to optimize Rust TUI (Terminal User Interface) development by centralizing shared resources and reducing code duplication across multiple TUI applications. The structure follows the DRY (Don't Repeat Yourself) principle and leverages Rust's workspace features to minimize disk space usage and simplify dependency management.

## Directory Structure

```
rust/
├── Cargo.toml              # Workspace root configuration
├── Rust-TUI-Structure.md   # This documentation
├── resources/              # Shared resources for all TUI applications
│   ├── components/         # Reusable TUI components library
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── file_browser.rs
│   │       ├── form_panel.rs
│   │       ├── helpers.rs
│   │       ├── list_panel.rs
│   │       └── toast.rs
│   └── crates/             # Additional shared crates (future use)
└── dev/                    # Individual TUI application projects
    ├── bootstrapper/       # Bootstrapper TUI
    ├── chamon/             # Chamon TUI
    ├── detour/             # Detour TUI
    └── hasync/             # Hsync TUI
```

## Design Goals

### 1. Space Efficiency
By using a Rust workspace with shared dependencies and components, we significantly reduce the overall disk space required. Instead of each TUI application maintaining its own copy of:
- Common dependencies (ratatui, crossterm, serde, etc.)
- Shared UI components (file browsers, form panels, list panels, toast notifications)
- Utility functions and helpers

All of these are centralized in the `resources/` directory and referenced by each TUI project, eliminating duplication.

### 2. Code Reusability
The `resources/components/` crate provides a library of pre-built, DRY (Don't Repeat Yourself) components that can be included and used across all TUI applications. This ensures:
- Consistent UI/UX across all applications
- Single source of truth for component implementations
- Easier maintenance and bug fixes (fix once, benefit everywhere)
- Faster development of new TUI applications

### 3. Dependency Management
The workspace-level `Cargo.toml` defines all shared dependencies in one place, ensuring:
- Consistent dependency versions across all projects
- Simplified dependency updates (update once, apply everywhere)
- Reduced compilation time through shared dependency compilation
- Better dependency resolution and conflict management

### 4. Project Organization
Each TUI application in the `dev/` directory maintains its own:
- Application-specific logic and state management
- Unique UI layouts and workflows
- Project-specific configuration
- Binary entry points

This separation allows each TUI to be developed independently while still benefiting from shared resources.

## Component Structure

### Shared Components (`resources/components/`)

The `tui-components` crate provides reusable components that are used across multiple TUI applications:

- **`file_browser.rs`**: File browser component for navigating file systems
- **`form_panel.rs`**: Form input panel with validation
- **`helpers.rs`**: Utility functions and helper methods
- **`list_panel.rs`**: Scrollable list panel component
- **`toast.rs`**: Toast notification system

These components are designed to be generic and configurable, allowing each TUI application to customize them for their specific needs while maintaining a consistent base implementation.

### Individual TUI Projects (`dev/`)

Each TUI project follows a similar structure based on the patterns established in the original `chamon` and `detour` projects:

#### Common Modules
- **`app.rs`**: Application state management
- **`config.rs`**: Configuration loading and management
- **`events.rs`**: Event handling and input processing
- **`ui.rs`**: UI rendering and layout
- **`main.rs`**: Binary entry point
- **`lib.rs`**: Library exports for use as a dependency

#### Project-Specific Modules
Some projects may have additional modules based on their specific functionality:
- **`chamon`**: Includes `baseline.rs` for baseline management
- **`detour`**: Includes modules for file operations, diff, injection, mirror, validation, and more

## Workspace Configuration

The root `Cargo.toml` defines a Rust workspace that includes:
- All TUI projects in `dev/`
- The shared components library in `resources/components/`

This configuration enables:
- Building all projects with a single `cargo build` command
- Running tests across all projects
- Sharing compiled dependencies across projects
- Unified dependency version management

## Usage

### Building All Projects
```bash
cd /root/_playground/rust
cargo build
```

### Building a Specific Project
```bash
cd /root/_playground/rust
cargo build -p bootstrapper
cargo build -p chamon-tui
cargo build -p detour
cargo build -p hasync
```

### Running a TUI Application
```bash
cd /root/_playground/rust
cargo run --bin bootstrapper
cargo run --bin chamon
cargo run --bin detour
cargo run --bin hasync
```

### Using Shared Components
In any TUI project's `Cargo.toml`:
```toml
[dependencies]
tui-components = { path = "../../resources/components" }
```

Then in your Rust code:
```rust
use tui_components::{FileBrowser, FormPanel, ListPanel, Toast};
```

## Benefits

1. **Reduced Disk Space**: Shared dependencies and components mean less duplication
2. **Faster Development**: Reusable components speed up new TUI development
3. **Consistency**: Shared components ensure consistent UI/UX across applications
4. **Maintainability**: Bug fixes and improvements to shared components benefit all applications
5. **Simplified Updates**: Update dependencies once at the workspace level
6. **Better Organization**: Clear separation between shared resources and application-specific code

## Future Enhancements

The `resources/crates/` directory is reserved for additional shared crates that may be needed in the future, such as:
- Shared configuration management
- Common data structures
- Utility libraries
- Shared networking or I/O abstractions

## Migration Notes

This structure is based on the existing TUI projects:
- `/root/RPi-Full/_playground/_dev/packages/chamon`
- `/root/RPi-Full/_playground/_dev/packages/detour`
- `/root/RPi-Full/_playground/_dev/packages/_tui-components`

The skeleton structure maintains compatibility with the original project layouts while providing the benefits of centralized resource management.

