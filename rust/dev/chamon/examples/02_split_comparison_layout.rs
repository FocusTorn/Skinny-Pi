// Split Comparison Layout Example
// Side-by-side comparison view for analyzing changes and baselines
// Perfect for detailed analysis and comparison workflows

/*
┌─────────────────────────────────────────────────────────────────────────────┐
│  CHAMON - Comparison View                              [Changes] [Baseline] │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌────────────────────────────────────┐  ┌─────────────────────────────────┐ │
│  │  File Changes                       │  │  Baseline Details              │ │
│  ├────────────────────────────────────┤  ├─────────────────────────────────┤ │
│  │  Filter: [All ▼] [Tracked ▼]       │  │  Active: 20241017-143022        │ │
│  │                                     │  │  Files: 42 changes             │ │
│  │  [M] /etc/config.txt               │  │  Created: 2 hours ago           │ │
│  │      Modified 2h ago                │  │                                 │ │
│  │      [View] [Track] [Diff]          │  │  Comparison Results:            │ │
│  │                                     │  │  ┌───────────────────────────┐ │ │
│  │  [N] /home/pi/newfile.sh           │  │  │ Changed: 15 files         │ │ │
│  │      New 4h ago                     │  │  │ New: 8 files              │ │ │
│  │      [View] [Track] [Diff]         │  │  │ Deleted: 2 files           │ │ │
│  │                                     │  │  │ Packages: +3, -1, ↑2       │ │ │
│  │  [M] /var/log/app.log               │  │  └───────────────────────────┘ │ │
│  │      Modified 6h ago                │  │                                 │ │
│  │      [View] [Track] [Diff]          │  │  Baseline History:              │ │
│  │                                     │  │  → 20241017-143022 (active)    │ │
│  │  [N] /opt/custom/script.py          │  │     20241015-091500             │ │
│  │      New 8h ago                     │  │     20241010-120000             │ │
│  │      [View] [Track] [Diff]          │  │     Initial Baseline            │ │
│  │                                     │  │                                 │ │
│  │  [Scroll: ↑↓]  Showing 4 of 42     │  │  [Compare] [Export] [Create]   │ │
│  └────────────────────────────────────┘  └─────────────────────────────────┘ │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Selected File Details                                               │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  Path: /etc/config.txt                                               │   │
│  │  Status: Modified | Tracked: Yes | Last modified: 2 hours ago        │   │
│  │                                                                       │   │
│  │  Diff Preview:                                                       │   │
│  │  - old_value = "previous"                                            │   │
│  │  + new_value = "updated"                                              │   │
│  │                                                                       │   │
│  │  [View Full Diff] [Open in Editor] [Track/Untrack] [Ignore]          │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  [F1: Help] [F2: Refresh] [F3: Create Baseline] [F4: Settings] [Q: Quit]    │
└─────────────────────────────────────────────────────────────────────────────┘

KEY IMPROVEMENTS:
- Parallel information: See changes and baseline context simultaneously
- Detailed file view: Bottom panel shows full context for selected item
- Better filtering: Filter options visible and accessible
- Contextual actions: Actions appear where relevant
- Efficient navigation: Keyboard shortcuts always visible
- No column switching: All information visible at once
*/

