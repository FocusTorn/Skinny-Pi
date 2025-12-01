# Sharables Cross-Platform Guide

## Overview

The sharables system now includes **Python scripts** that work on both **Windows** and **Linux/Debian** systems. The Python scripts provide the same functionality as the bash scripts but with cross-platform compatibility.

## Requirements

### Python
- **Python 3.6+** (usually pre-installed on Linux, available for Windows)
- **PyYAML** library: `pip install pyyaml`

### Git
- Git must be installed and in PATH
- Works with Git for Windows, Git on Linux, etc.

## Installation

### Install PyYAML

**Linux/Debian:**
```bash
pip3 install pyyaml
# or
python3 -m pip install pyyaml
```

**Windows:**
```cmd
pip install pyyaml
# or
python -m pip install pyyaml
```

## Scripts

### Python Scripts (Cross-Platform)

- **`sharables-deploy.py`** - Deploy sections to target paths
- **`sharables-git-helper.py`** - Git operations helper

### Bash Scripts (Linux/Debian)

- **`sharables-deploy.sh`** - Linux version
- **`sharables-git-helper.sh`** - Linux version

**Note:** Both sets of scripts provide the same functionality. Use Python scripts for cross-platform compatibility.

## Usage

### Deployment

**Linux/Debian:**
```bash
# Python (cross-platform)
python3 _playground/_scripts/sharables-deploy.py deploy --sharables-dir .sharables

# Or bash (Linux only)
SHARABLES_DIR=.sharables _playground/_scripts/sharables-deploy.sh deploy
```

**Windows:**
```cmd
# Python (cross-platform)
python _playground\_scripts\sharables-deploy.py deploy --sharables-dir .sharables
```

### Git Operations

**Linux/Debian:**
```bash
# Python (cross-platform)
python3 _playground/_scripts/sharables-git-helper.py status --sharables-dir .sharables
python3 _playground/_scripts/sharables-git-helper.py commit --message "Update" --sharables-dir .sharables
python3 _playground/_scripts/sharables-git-helper.py sync --message "Update" --sharables-dir .sharables
```

**Windows:**
```cmd
# Python (cross-platform)
python _playground\_scripts\sharables-git-helper.py status --sharables-dir .sharables
python _playground\_scripts\sharables-git-helper.py commit --message "Update" --sharables-dir .sharables
python _playground\_scripts\sharables-git-helper.py sync --message "Update" --sharables-dir .sharables
```

## Path Handling

### Cross-Platform Paths

The Python scripts handle paths correctly on both platforms:

**Linux/Debian:**
```yaml
deployments:
  - section: cursor-rules
    target: .cursor/rules          # Relative path
    method: symlink
  - section: global-utilities
    target: ~/.local/share/sharables  # Home directory
    method: symlink
```

**Windows:**
```yaml
deployments:
  - section: cursor-rules
    target: .cursor\rules          # Relative path (backslash or forward slash both work)
    method: symlink
  - section: global-utilities
    target: C:\Users\YourName\.local\share\sharables  # Absolute path
    method: symlink
  - section: shared-configs
    target: ~/.config/sharables    # ~ expands to user home on Windows too
    method: symlink
```

## Symlinks on Windows

### Yes, Windows Supports Symlinks!

Windows **does support symlinks** (since Vista/Server 2008). They work identically to Linux symlinks once configured.

### Requirements

To create symlinks on Windows, you need **one** of:

1. **Developer Mode** (Recommended - Easiest)
   - Settings → Update & Security → For developers
   - Enable Developer Mode
   - One-time setup, no admin needed

2. **Administrator Privileges**
   - Right-click → Run as administrator
   - Must run as admin each time

3. **Copy Method** (Fallback)
   - Use `method: copy` in config
   - Doesn't maintain git connection, but works everywhere

### Enable Developer Mode (Recommended)

**Windows 10/11:**
1. Open **Settings** (Win + I)
2. Go to **Update & Security** → **For developers**
3. Enable **Developer Mode**
4. Restart if prompted

**Benefits:**
- ✅ No need to run as Administrator
- ✅ Works for all users
- ✅ One-time setup

### How It Works

Windows symlinks work exactly like Linux symlinks:
- Point to source location
- Maintain git tracking
- Work across drives
- Same functionality on both platforms

See `Sharables-Windows-Symlinks.md` for detailed information.

## Configuration File

The configuration file (`.sharables-deploy.yaml`) works the same on both platforms:

```yaml
deployments:
  - section: cursor-rules
    target: .cursor/rules
    method: symlink
```

Paths can use:
- Forward slashes `/` (works on both platforms)
- Backslashes `\` (Windows style)
- `~` for home directory (expands correctly on both)

## Complete Workflow

### Initial Setup (Cross-Platform)

**Linux/Debian:**
```bash
# Clone repo
git clone --filter=blob:none --sparse <repo-url> .sharables
cd .sharables

# Checkout sections
./scripts/sharables-checkout.sh cursor-rules global-utilities

# Deploy (Python - cross-platform)
python3 ../_playground/_scripts/sharables-deploy.py deploy --sharables-dir .
```

**Windows:**
```cmd
# Clone repo
git clone --filter=blob:none --sparse <repo-url> .sharables
cd .sharables

# Checkout sections (bash scripts work in Git Bash)
bash scripts/sharables-checkout.sh cursor-rules global-utilities

# Deploy (Python - cross-platform)
python ..\_playground\_scripts\sharables-deploy.py deploy --sharables-dir .
```

### Daily Workflow

**Linux/Debian:**
```bash
# Edit files
vim .cursor/rules/formatting/markdown.mdc

# Status
python3 _playground/_scripts/sharables-git-helper.py status --sharables-dir .sharables

# Commit and push
python3 _playground/_scripts/sharables-git-helper.py sync --message "Update" --sharables-dir .sharables
```

**Windows:**
```cmd
# Edit files
notepad .cursor\rules\formatting\markdown.mdc

# Status
python _playground\_scripts\sharables-git-helper.py status --sharables-dir .sharables

# Commit and push
python _playground\_scripts\sharables-git-helper.py sync --message "Update" --sharables-dir .sharables
```

## Auto-Detection

The Python scripts can auto-detect the sharables directory:

```bash
# From anywhere in your project
python3 _playground/_scripts/sharables-git-helper.py status
# Automatically finds .sharables or sharables directory
```

## Platform-Specific Notes

### Linux/Debian
- Symlinks work without special permissions
- Use forward slashes in paths (though backslashes also work)
- Bash scripts available as alternative

### Windows
- Symlinks may require Developer Mode or Admin rights
- Use backslashes or forward slashes (both work)
- Python scripts recommended for cross-platform compatibility
- Git Bash can run bash scripts if needed

## Troubleshooting

### PyYAML Not Found

```bash
# Install PyYAML
pip install pyyaml
# or
pip3 install pyyaml
```

### Symlink Creation Fails (Windows)

1. Enable Developer Mode (see above)
2. Or run as Administrator
3. Or use `method: copy` in config

### Git Not Found

Install Git:
- **Windows**: Download from https://git-scm.com/
- **Linux**: `sudo apt install git` (Debian/Ubuntu)

### Path Issues

- Use forward slashes `/` for compatibility (works on both)
- Or use `~` for home directory (expands correctly)
- Absolute paths work on both platforms

## Summary

✅ **Python scripts work on both Windows and Linux**  
✅ **Same configuration file format**  
✅ **Auto-detection of sharables directory**  
✅ **Handles path differences automatically**  
✅ **Symlink support with fallback to copy**  

Use the Python scripts (`.py`) for cross-platform compatibility, or use the bash scripts (`.sh`) if you're only on Linux/Debian.

