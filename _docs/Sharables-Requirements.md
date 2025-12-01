# Sharables Requirements

## Cross-Platform Support

The sharables system supports both **Windows** and **Linux/Debian** through Python scripts.

## Required Software

### Python 3.6+
- **Linux/Debian**: Usually pre-installed
  ```bash
  python3 --version  # Check version
  ```
- **Windows**: Download from https://www.python.org/downloads/
  ```cmd
  python --version  # Check version
  ```

### PyYAML Library
- **Install on Linux/Debian:**
  ```bash
  pip3 install pyyaml
  # or
  python3 -m pip install pyyaml
  ```
- **Install on Windows:**
  ```cmd
  pip install pyyaml
  # or
  python -m pip install pyyaml
  ```

### Git
- **Linux/Debian**: 
  ```bash
  sudo apt install git  # Debian/Ubuntu
  ```
- **Windows**: Download from https://git-scm.com/download/win

## Optional: Symlink Support on Windows

For symlink support on Windows (recommended):

### Option 1: Developer Mode (Recommended)
1. Open **Settings** → **Update & Security** → **For developers**
2. Enable **Developer Mode**
3. Allows symlink creation without admin rights

### Option 2: Run as Administrator
- Right-click Command Prompt/PowerShell
- Select "Run as Administrator"
- Create symlinks with admin privileges

### Option 3: Use Copy Method
- If symlinks don't work, use `method: copy` in config
- Note: Copy method doesn't maintain git connection

## Verification

### Check Python
```bash
python3 --version  # Linux
python --version    # Windows
```

### Check PyYAML
```bash
python3 -c "import yaml; print('PyYAML OK')"  # Linux
python -c "import yaml; print('PyYAML OK')"  # Windows
```

### Check Git
```bash
git --version
```

## Quick Setup

### Linux/Debian
```bash
# Install PyYAML
pip3 install pyyaml

# Verify
python3 -c "import yaml; print('Ready!')"
```

### Windows
```cmd
# Install PyYAML
pip install pyyaml

# Verify
python -c "import yaml; print('Ready!')"

# Enable Developer Mode (for symlinks)
# Settings → Update & Security → For developers → Enable Developer Mode
```

## That's It!

Once Python, PyYAML, and Git are installed, you're ready to use the sharables system on both platforms.

