// Tabbed Interface Layout Example
// Modern tab-based navigation with dedicated views for each major function
// Reduces cognitive load by separating concerns into distinct views

/*
┌─────────────────────────────────────────────────────────────────────────────┐
│  CHAMON                                    [Dashboard] [Changes] [Baselines] │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Dashboard                                                             │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │                                                                       │   │
│  │  System Status                                                        │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │   │
│  │  │ Active        │  │ Changes      │  │ Tracked      │              │   │
│  │  │ Baseline      │  │ Today        │  │ Files        │              │   │
│  │  │               │  │              │  │              │              │   │
│  │  │ Initial (/)   │  │ 42 changes   │  │ 156 files    │              │   │
│  │  │ 3 days old    │  │ 12 new       │  │ 12 untracked │              │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │   │
│  │                                                                       │   │
│  │  Recent Activity                                                      │   │
│  │  • Baseline created: 20241017-143022 (42 changes)                   │   │
│  │  • File tracked: /etc/config.txt                                     │   │
│  │  • Baseline compared: 15 changed, 8 new, 2 deleted                   │   │
│  │                                                                       │   │
│  │  Quick Actions                                                        │   │
│  │  [Create Baseline] [View Changes] [Manage Baselines]                 │   │
│  │                                                                       │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Changes Tab (when selected)                                          │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  View: [All] [Modified] [New] [Tracked] [Untracked]                  │   │
│  │                                                                       │   │
│  │  [M] /etc/config.txt          Modified    2h ago    [Track] [View]    │   │
│  │  [N] /home/pi/newfile.sh      New         4h ago    [Track] [View]    │   │
│  │  [M] /var/log/app.log          Modified    6h ago    [Track] [View]    │   │
│  │  [N] /opt/custom/script.py    New         8h ago    [Track] [View]    │   │
│  │                                                                       │   │
│  │  Selected: /etc/config.txt                                           │   │
│  │  [View Diff] [Open File] [Track/Untrack] [Ignore]                    │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Baselines Tab (when selected)                                        │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  → 20241017-143022  (42 changes)  Active    [Compare] [Export]       │   │
│  │     20241015-091500  (18 changes)          [Compare] [Export]        │   │
│  │     20241010-120000  (5 changes)           [Compare] [Export]        │   │
│  │     Initial Baseline  (15,234 files)       [Compare] [Export]        │   │
│  │                                                                       │   │
│  │  [Create New Baseline] [Initialize Baseline] [Delete Selected]      │   │
│  │                                                                       │   │
│  │  Comparison Results (when comparing):                                 │   │
│  │  Changed: 15 | New: 8 | Deleted: 2 | Packages: +3, -1, ↑2           │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  Status: Ready | Press Tab to switch views | '?' for help                    │
└─────────────────────────────────────────────────────────────────────────────┘

KEY IMPROVEMENTS:
- Clear separation: Each major function has its own dedicated view
- Reduced complexity: Only see what's relevant to current task
- Better organization: Related information grouped together
- Modern UX: Tabbed interface is familiar and intuitive
- Focus mode: Each tab can be optimized for its specific purpose
- Easy navigation: Tab switching is fast and clear
*/

