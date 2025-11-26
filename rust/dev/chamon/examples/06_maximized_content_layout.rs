// Maximized Content Layout Example
// Focus on content with collapsible panels and context-sensitive actions
// Maximizes screen real estate for the primary task

/*
┌─────────────────────────────────────────────────────────────────────────────┐
│  CHAMON                                    [≡ Menu] [⚙ Settings] [× Close] │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  File Changes                    [All] [Modified] [New] [Tracked]     │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │                                                                       │   │
│  │  [M] /etc/config.txt                                                 │   │
│  │      Modified: 2 hours ago | Tracked: Yes | Size: 1.2 KB            │   │
│  │      [View Diff] [Open] [Track/Untrack] [Ignore]                    │   │
│  │                                                                       │   │
│  │  ┌──────────────────────────────────────────────────────────────┐   │   │
│  │  │ Diff Preview:                                                │   │   │
│  │  │ - old_value = "previous"                                      │   │   │
│  │  │ + new_value = "updated"                                       │   │   │
│  │  │ - another_line = "removed"                                     │   │   │
│  │  │ + new_line = "added"                                          │   │   │
│  │  └──────────────────────────────────────────────────────────────┘   │   │
│  │                                                                       │   │
│  │  [N] /home/pi/newfile.sh                                            │   │
│  │      New: 4 hours ago | Tracked: No | Size: 456 B                   │   │
│  │      [View] [Track] [Open] [Ignore]                                 │   │
│  │                                                                       │   │
│  │  ┌──────────────────────────────────────────────────────────────┐   │   │
│  │  │ File Preview:                                                 │   │   │
│  │  │ #!/bin/bash                                                   │   │   │
│  │  │ echo "New script"                                              │   │   │
│  │  └──────────────────────────────────────────────────────────────┘   │   │
│  │                                                                       │   │
│  │  [M] /var/log/app.log                                               │   │
│  │      Modified: 6 hours ago | Tracked: Yes | Size: 2.3 MB          │   │
│  │      [View Diff] [Open] [Track/Untrack] [Ignore]                   │   │
│  │                                                                       │   │
│  │  [Scroll: ↑↓] Showing 3 of 42 | [Refresh] [Create Baseline]       │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Sidebar (Collapsible) [<]                                            │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  Active Baseline                                                     │   │
│  │  Initial (/)                                                         │   │
│  │  15,234 files                                                         │   │
│  │  3 days old                                                          │   │
│  │  [View] [Compare]                                                    │   │
│  │                                                                       │   │
│  │  Quick Stats                                                         │   │
│  │  • Changes: 42                                                       │   │
│  │  • Tracked: 156                                                      │   │
│  │  • Untracked: 12                                                     │   │
│  │                                                                       │   │
│  │  Actions                                                             │   │
│  │  [Create Baseline]                                                  │   │
│  │  [Compare]                                                           │   │
│  │  [Export]                                                            │   │
│  │                                                                       │   │
│  │  [Hide Sidebar]                                                      │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  Status: Ready | Last check: 2m ago | [F1: Help] [F2: Refresh] [Q: Quit]    │
└─────────────────────────────────────────────────────────────────────────────┘

KEY IMPROVEMENTS:
- Maximum content area: Most screen space for file details
- Inline previews: See diffs and file content without leaving list
- Collapsible sidebar: Hide when not needed, show when needed
- Context-rich: All relevant info visible for each file
- Action-oriented: Actions appear with each item
- Clean interface: Minimal chrome, maximum content
- Flexible layout: Adapts to screen size and user preference
*/

