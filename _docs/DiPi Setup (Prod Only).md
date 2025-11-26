# Raspberry Pi Development Setup Overview

## 1. :: Architecture Overview

### 1.1. :: Development Workflow

**Hybrid Development Approach**:
- **Windows Machine**: Primary development environment
  - Better IDE/tools (Cursor, VS Code)
  - Faster builds and compilation
  - Easier Git management
  - Cross-compilation for ESP32 and Rust
- **GitHub**: Version control and CI/CD
  - Source code repository
  - Automated builds and deployments
  - History and backup
- **Raspberry Pi (DietPi)**: Production environment
  - Runtime execution
  - Hardware integration testing
  - Service hosting (HomeAssistant)

### 1.2. :: Monorepo Structure

**Single Repository Approach**:
- All projects in one repository
- Clear separation by technology/area
- Shared configurations and scripts
- Easier cross-project dependencies
- Single deployment pipeline

**Benefits**:
- HomeAssistant can use Python scripts from the same repo
- ESP32 devices integrate with HomeAssistant configs
- System-wide configurations in one place
- Single Git history for entire system

---

## 2. :: File Structure

### 2.1. :: Windows Development Workspace

```
D:\_dev\_Projects\_raspberry-pi-setup\
├── .github/
│   └── workflows/
│       ├── deploy-python.yml
│       ├── build-rust.yml
│       └── deploy-to-pi.yml
├── docs/
│   ├── setup.md
│   ├── python/
│   ├── esp32/
│   └── homeassistant/
├── python/
│   ├── scripts/              # Utility scripts
│   ├── projects/             # Individual Python projects
│   │   ├── sensor-reader/
│   │   └── data-processor/
│   └── requirements.txt      # Global Python dependencies
├── rust/
│   ├── tui-apps/
│   │   ├── my-tui-app/
│   │   │   ├── src/
│   │   │   ├── Cargo.toml
│   │   │   └── README.md
│   │   └── another-app/
│   └── README.md
├── esp32/
│   ├── projects/             # Individual ESP32 projects
│   │   ├── sensor-node/
│   │   └── actuator-control/
│   └── shared/               # Shared ESP32 libraries
├── homeassistant/
│   ├── configuration.yaml
│   ├── automations/
│   ├── scripts/
│   └── custom_components/
├── scripts/
│   ├── setup/                # Initial setup scripts
│   ├── maintenance/          # System maintenance
│   └── deployment/           # Deployment helpers
├── config/
│   ├── system/               # System-wide configs
│   └── services/             # Service configs (systemd, etc.)
├── .gitignore
└── README.md
```

### 2.2. :: Raspberry Pi Production Workspace

```
/root/_playground/             # PRIMARY WORKSPACE ROOT
├── .cursor/                   # Cursor workspace config
│   └── settings.json
├── .cursor-workspace          # Workspace file
├── .git/                      # Git repository
├── python/
│   ├── scripts/              # Source code (needed for runtime)
│   ├── projects/
│   └── .venv/                # Virtual environment (excluded from indexing)
├── rust/
│   └── bin/                  # Compiled binaries only
│       └── my-tui-app        # No source code needed
├── esp32/
│   └── projects/             # Project files (if kept on Pi)
├── homeassistant/
│   ├── configuration.yaml    # Config files (indexed)
│   ├── automations/
│   ├── scripts/
│   └── .storage/             # Runtime data (excluded)
├── config/
│   └── system/               # System configs (indexed)
└── scripts/
    └── deployment/
```

---

## 3. :: Project Type Workflows

### 3.1. :: Python Projects

**Development Flow**:
```
Windows: Write Python code → Test locally → Commit to GitHub
    ↓
GitHub: Version control
    ↓
Pi: Pull → Install dependencies → Run
```

**What's on Pi**:
- ✅ Source code (needed for runtime)
- ✅ Virtual environment (`.venv/`)
- ✅ Installed dependencies
- ❌ Build artifacts (not applicable)

**Deployment**:
- Manual: `git pull` on Pi, activate venv, run scripts
- Automated: GitHub Actions SSH deployment

### 3.2. :: Rust Projects

**Development Flow**:
```
Windows: Write Rust code → Compile locally → Test
    ↓
GitHub: Push source code
    ↓
GitHub Actions: Cross-compile for ARM (Pi architecture)
    ↓
Pi: Download binary → Run (no Rust toolchain needed)
```

**What's on Pi**:
- ✅ Compiled binary only (e.g., `my-tui-app`)
- ✅ Config files (if needed)
- ❌ Source code (not needed)
- ❌ Rust toolchain (not needed)

**Cross-Compilation Target**:
- `armv7-unknown-linux-gnueabihf` (Raspberry Pi 4)

**Benefits**:
- No runtime dependencies
- Small footprint (~5MB binary)
- Fast execution (native ARM code)
- Easy updates (replace binary)

### 3.3. :: ESP32 Projects

**Development Flow**:
```
Windows: Write ESP32 code → Build → Flash to device
    ↓
GitHub: Version control source code
    ↓
Pi: (Optional) Use as programming hub
```

**What's on Pi**:
- ❌ Usually nothing (firmware flashed directly to devices)
- ✅ Optional: Project files if using Pi as programming hub

**Development Tools**:
- PlatformIO or Arduino IDE on Windows
- Cross-compilation for ESP32 architecture

### 3.4. :: HomeAssistant

**Development Flow**:
```
Windows: Edit YAML configs → Validate → Commit
    ↓
GitHub: Version control
    ↓
Pi: Pull → Restart HomeAssistant → Test
```

**What's on Pi**:
- ✅ Configuration files (YAML)
- ✅ Custom components (if any)
- ✅ Automations and scripts
- ❌ HomeAssistant core source (managed by system)

**Integration Points**:
- Can call Python scripts from `python/scripts/`
- Can integrate with ESP32 devices
- Uses system configs from `config/`

---

## 4. :: GitHub Setup

### 4.1. :: Repository Structure

**Single Monorepo**: `raspberry-pi-setup`

**Branch Strategy**:
- `main` - Production system (deployed to Pi)
- `develop` - Development/testing
- Feature branches - New projects/features

### 4.2. :: GitHub Actions Workflows

**Rust Build Workflow** (`build-rust.yml`):
- Triggers on push to `main`
- Cross-compiles Rust projects for ARM
- Creates release artifacts
- Optionally deploys binaries to Pi

**Python Deployment Workflow** (`deploy-python.yml`):
- Triggers on push to `main`
- Validates Python code
- Deploys to Pi via SSH
- Installs dependencies
- Restarts services if needed

**HomeAssistant Deployment Workflow** (`deploy-homeassistant.yml`):
- Triggers on push to `main`
- Validates YAML configs
- Deploys to Pi via SSH
- Restarts HomeAssistant service

### 4.3. :: GitHub Secrets

Required secrets for automated deployment:
- `PI_HOST` - Raspberry Pi IP address
- `PI_USER` - SSH username (root for DietPi)
- `PI_SSH_KEY` - SSH private key for authentication

### 4.4. :: .gitignore

```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
.venv/
venv/
ENV/
env/

# Rust
target/
**/*.rs.bk
Cargo.lock

# ESP32 / PlatformIO
.pio/
.vscode/

# HomeAssistant
homeassistant/.storage/
homeassistant/.cloud/

# System
.DS_Store
Thumbs.db
*.swp
*.swo
*~

# IDE
.vscode/
.idea/
*.code-workspace

# Logs
*.log
```

---

## 5. :: Cursor Workspace Configuration

### 5.1. :: Windows Workspace

**Location**: `D:\_dev\_Projects\_raspberry-pi-setup\.cursor-workspace`

```json
{
  "folders": [
    {
      "name": "Raspberry Pi Setup",
      "path": "."
    }
  ],
  "settings": {
    "files.exclude": {
      "**/target": true,
      "**/__pycache__": true,
      "**/.pio": true,
      "**/.venv": true,
      "**/dist": true,
      "**/build": true
    },
    "search.exclude": {
      "**/target": true,
      "**/__pycache__": true,
      "**/.pio": true,
      "**/node_modules": true
    },
    "files.watcherExclude": {
      "**/target/**": true,
      "**/__pycache__/**": true,
      "**/.pio/**": true,
      "**/.venv/**": true
    },
    "[rust]": {
      "editor.defaultFormatter": "rust-lang.rust-analyzer"
    },
    "[python]": {
      "editor.defaultFormatter": "ms-python.black-formatter"
    },
    "[yaml]": {
      "editor.defaultFormatter": "redhat.vscode-yaml"
    }
  }
}
```

### 5.2. :: Pi Workspace

**Location**: `/root/_playground/.cursor-workspace`

```json
{
  "folders": [
    {
      "name": "Raspberry Pi Playground",
      "path": "."
    }
  ],
  "settings": {
    "files.exclude": {
      "**/__pycache__": true,
      "**/.venv": true,
      "**/.storage": true,
      "**/target": true,
      "**/.pio": true,
      "**/node_modules": true
    },
    "search.exclude": {
      "**/__pycache__": true,
      "**/.venv": true,
      "**/.storage": true,
      "**/target": true
    },
    "files.watcherExclude": {
      "**/.venv/**": true,
      "**/.storage/**": true,
      "**/target/**": true
    }
  }
}
```

### 5.3. :: Indexing Strategy

**Index (Primary)**:
- Python source code (`python/scripts/`, `python/projects/`)
- Rust source code (`rust/tui-apps/`)
- ESP32 source code (`esp32/projects/`)
- HomeAssistant configs (`homeassistant/*.yaml`)
- System configs (`config/`)
- Documentation (`docs/`)

**Exclude from Indexing**:
- Build artifacts (`target/`, `dist/`, `build/`)
- Python cache (`__pycache__/`, `.venv/`)
- HomeAssistant runtime data (`.storage/`)
- PlatformIO build (`.pio/`)
- Dependencies (`node_modules/`)

---

## 6. :: SSH Configuration

### 6.1. :: Windows SSH Config

**Location**: `C:\Users\<username>\.ssh\config`

```
Host RPi-Playground
    HostName 192.168.1.171
    User root
    IdentityFile C:\Users\<username>\.ssh\rpi_key
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 6.2. :: Remote Development

**Cursor Remote SSH**:
- Connect to `RPi-Playground`
- Open workspace: `/root/_playground/`
- Full IDE experience on Pi files
- Edit directly on Pi when needed

---

## 7. :: Deployment Strategies

### 7.1. :: Manual Deployment

**Python**:
```bash
# On Pi
cd /root/_playground
git pull
source python/.venv/bin/activate
pip install -r python/requirements.txt
python python/scripts/my_script.py
```

**Rust**:
```bash
# On Windows (after cross-compilation)
scp target/armv7-unknown-linux-gnueabihf/release/my-tui-app root@192.168.1.171:/root/_playground/rust/bin/

# On Pi
chmod +x /root/_playground/rust/bin/my-tui-app
/root/_playground/rust/bin/my-tui-app
```

**HomeAssistant**:
```bash
# On Pi
cd /root/_playground
git pull
# Copy configs to HomeAssistant directory
cp homeassistant/*.yaml /opt/homeassistant/config/
systemctl restart homeassistant
```

### 7.2. :: Automated Deployment (GitHub Actions)

**Example Rust Deployment**:
```yaml
name: Build and Deploy Rust

on:
  push:
    branches: [main]
    paths:
      - 'rust/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          target: armv7-unknown-linux-gnueabihf
      - name: Build
        run: |
          cd rust/tui-apps/my-tui-app
          cargo build --release --target armv7-unknown-linux-gnueabihf
      - name: Deploy to Pi
        uses: appleboy/scp-action@master
        with:
          host: ${{ secrets.PI_HOST }}
          username: ${{ secrets.PI_USER }}
          key: ${{ secrets.PI_SSH_KEY }}
          source: "rust/tui-apps/my-tui-app/target/armv7-unknown-linux-gnueabihf/release/my-tui-app"
          target: "/root/_playground/rust/bin/"
```

---

## 8. :: Best Practices

### 8.1. :: Development

- ✅ Develop on Windows for better tooling
- ✅ Test locally when possible
- ✅ Use version control for everything
- ✅ Keep configs in version control
- ✅ Document setup and deployment processes

### 8.2. :: Deployment

- ✅ Use automated deployments via GitHub Actions
- ✅ Test on Pi before marking as production
- ✅ Keep binaries and source separate
- ✅ Use environment variables for secrets
- ✅ Implement rollback procedures

### 8.3. :: Organization

- ✅ Single monorepo for related projects
- ✅ Clear separation by technology/area
- ✅ Shared configs in `config/` directory
- ✅ Documentation in `docs/` directory
- ✅ Scripts in `scripts/` directory

### 8.4. :: Security

- ✅ Use SSH keys, not passwords
- ✅ Store secrets in GitHub Secrets
- ✅ Use `.gitignore` for sensitive files
- ✅ Limit SSH access to necessary IPs
- ✅ Keep dependencies updated

---

## 9. :: Quick Reference

### 9.1. :: Key Paths

**Windows Development**:
- Workspace: `D:\_dev\_Projects\_raspberry-pi-setup\`

**Raspberry Pi Production**:
- Workspace: `/root/_playground/`
- Rust binaries: `/root/_playground/rust/bin/`
- Python scripts: `/root/_playground/python/scripts/`
- HomeAssistant configs: `/root/_playground/homeassistant/`

### 9.2. :: Common Commands

**Git Operations**:
```bash
# Windows: Commit and push
git add .
git commit -m "Description"
git push origin main

# Pi: Pull latest
cd /root/_playground
git pull
```

**Rust Cross-Compilation**:
```bash
# Windows
rustup target add armv7-unknown-linux-gnueabihf
cargo build --release --target armv7-unknown-linux-gnueabihf
```

**Python Virtual Environment**:
```bash
# Windows
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

# Pi
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## 10. :: Next Steps

1. **Initialize Repository**:
   - Create GitHub repository
   - Clone to Windows workspace
   - Set up initial structure

2. **Configure SSH**:
   - Generate SSH key pair
   - Add public key to Pi
   - Configure SSH config on Windows

3. **Set Up Workspaces**:
   - Create Cursor workspace files
   - Configure indexing exclusions
   - Test remote connection

4. **Create GitHub Actions**:
   - Set up deployment workflows
   - Configure secrets
   - Test automated deployments

5. **Documentation**:
   - Create project-specific READMEs
   - Document setup procedures
   - Maintain changelog

---

## 11. :: Troubleshooting

### 11.1. :: Common Issues

**SSH Connection Failed**:
- Verify IP address and user (root for DietPi)
- Check SSH key permissions
- Verify firewall settings

**Cross-Compilation Errors**:
- Ensure Rust target is installed
- Check Cargo.toml for correct target
- Verify linker is available

**Python Import Errors on Pi**:
- Activate virtual environment
- Install dependencies: `pip install -r requirements.txt`
- Check Python path

**HomeAssistant Config Errors**:
- Validate YAML syntax
- Check indentation
- Review HomeAssistant logs

### 11.2. :: Getting Help

- Check project documentation in `docs/`
- Review GitHub Actions logs
- Check Pi system logs: `journalctl -u <service>`
- Verify file permissions on Pi

---

**Last Updated**: 2024-12-19
**Maintained By**: Development Team

