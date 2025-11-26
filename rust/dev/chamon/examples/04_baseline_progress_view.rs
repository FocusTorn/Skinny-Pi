// Baseline Progress View Example
// Optimized layout for monitoring baseline creation progress
// Shows real-time progress with worker threads and completion status

/*
┌─────────────────────────────────────────────────────────────────────────────┐
│  CHAMON - Creating Baseline                                    [Cancel] [X] │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  Creating Initial Baseline                                                   │
│  Scan Path: /media/pi/clean-pi/rootfs → Remap To: /                        │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Progress Overview                                                    │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  Files Processed: 12,456 / ~50,000 (estimated)                      │   │
│  │  ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 25%   │   │
│  │  Elapsed: 2m 34s | Estimated Remaining: 7m 42s                       │   │
│  │                                                                       │   │
│  │  Active Workers: 8 threads                                           │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Active Workers                                                       │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  ⣾ /usr/lib         2,341 files  |  Scanning: /usr/lib/python3.11  │   │
│  │  ⣽ /var/log           892 files  |  Scanning: /var/log/app.log     │   │
│  │  ⣻ /etc               1,156 files  |  Scanning: /etc/network         │   │
│  │  ⢿ /opt                 234 files  |  Scanning: /opt/custom           │   │
│  │  ⡿ /home/pi            445 files  |  Scanning: /home/pi/.config    │   │
│  │  ⣟ /boot/firmware      567 files  |  Scanning: /boot/firmware/over  │   │
│  │  ⣯ /media               123 files  |  Scanning: /media/usb          │   │
│  │  ⣷ /tmp                  89 files  |  Scanning: /tmp/tempfile        │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Completed Directories                                                │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  ✓ /bin                   156 files                                  │   │
│  │  ✓ /sbin                   89 files                                  │   │
│  │  ✓ /lib                    234 files                                 │   │
│  │  ✓ /root                   12 files                                  │   │
│  │  ✓ /sys                    0 files (excluded)                        │   │
│  │  ✓ /proc                   0 files (excluded)                        │   │
│  │  ... (12 more)                                                        │   │
│  │                                                                       │   │
│  │  [Show All] [Collapse Completed]                                     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Package Database                                                      │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  Building package file database...                                    │   │
│  │  Processed: 1,234 / 2,456 packages                                   │   │
│  │  ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 50%   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  [ESC: Cancel] [P: Pause] [Space: Toggle Details]                           │
└─────────────────────────────────────────────────────────────────────────────┘

KEY IMPROVEMENTS:
- Real-time progress: Visual progress bars and time estimates
- Worker visibility: See what each thread is doing
- Completion tracking: Clear indication of what's done
- Package status: Separate progress for package database
- Action controls: Easy access to cancel/pause
- Information density: Maximum useful info without clutter
- Visual feedback: Spinners and progress indicators
*/

