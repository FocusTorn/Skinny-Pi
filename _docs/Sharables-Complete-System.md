# Sharables Complete System Overview

## What You Asked For

You wanted a system where:
- Sections can be deployed to **custom paths** (e.g., `.cursor/rules`, `~/.local/share/sharables`)
- Git **tracks where code came from** and where it should be pushed
- Sections can be "cut and pasted" to different directories while maintaining source control

## What Was Built

A complete deployment system that:
- ✅ Maps sections to target paths via YAML config
- ✅ Uses symlinks to maintain git connection
- ✅ Tracks changes at target locations in the sharables repo
- ✅ Provides helper scripts for easy git operations

## System Components

### 1. Setup Scripts
- **`setup-sharables-repo.sh`** - Creates the monorepo structure
- **`migrate-to-sharables.sh`** - Migrates existing content

### 2. Deployment System
- **`sharables-deploy.sh`** - Deploys sections to target paths
- **`.sharables-deploy.yaml`** - Configuration file mapping sections to paths

### 3. Git Helpers
- **`sharables-git-helper.sh`** - Git operations from deployed locations
- **`sharables-checkout.sh`** - Checkout specific sections
- **`sharables-push.sh`** - Push changes
- **`sharables-pull.sh`** - Pull updates

## How It Works

### Step 1: Create Repository

```bash
_playground/_scripts/setup-sharables-repo.sh sharables your-github-username
```

### Step 2: Migrate Content

```bash
_playground/_scripts/migrate-to-sharables.sh ../sharables
```

### Step 3: Configure Deployment

Edit `.sharables/.sharables-deploy.yaml`:

```yaml
deployments:
  - section: cursor-rules
    target: .cursor/rules
    method: symlink
    
  - section: global-utilities
    target: ~/.local/share/sharables
    method: symlink
```

### Step 4: Deploy in Projects

```bash
# Clone repo
git clone --filter=blob:none --sparse <repo-url> .sharables
cd .sharables
./scripts/sharables-checkout.sh cursor-rules global-utilities

# Deploy to target paths
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-deploy.sh deploy
```

### Step 5: Work with Deployed Sections

```bash
# Edit files at target location
vim .cursor/rules/formatting/markdown.mdc

# Changes are tracked in .sharables/
cd .sharables
git status  # Shows changes to cursor-rules/

# Commit and push
git add cursor-rules/
git commit -m "Update cursor rules"
git push origin main
```

## Key Features

### 1. Flexible Path Mapping

You specify where each section goes:

```yaml
- section: cursor-rules
  target: .cursor/rules          # Relative path
  
- section: global-utilities
  target: ~/.local/share/sharables  # Home directory
  
- section: shared-configs
  target: /absolute/path/configs    # Absolute path
```

### 2. Git Tracking Maintained

- Files at target locations are **symlinked** to sharables repo
- Changes at `.cursor/rules/` are tracked in `.sharables/cursor-rules/`
- Git operations happen in `.sharables/` directory
- Source control knows exactly where code came from

### 3. Easy Git Operations

Use the git helper from anywhere:

```bash
# Status
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh status

# Commit
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh commit "Update cursor rules"

# Push
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh push

# Sync (commit + push)
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh sync "Update"
```

## Directory Structure

```
Project Root/
├── .sharables/                    # Git repo (sparse checkout)
│   ├── .git/
│   ├── cursor-rules/              # Actual files
│   │   └── formatting/
│   ├── global-utilities/
│   ├── .sharables-deploy.yaml     # Deployment config
│   └── scripts/                   # Helper scripts
│
└── .cursor/
    └── rules -> ../.sharables/cursor-rules  # Symlink!
```

## Workflow Example

### Initial Setup

```bash
# 1. Clone sharables
git clone --filter=blob:none --sparse git@github.com:user/sharables.git .sharables

# 2. Checkout sections
cd .sharables
./scripts/sharables-checkout.sh cursor-rules global-utilities

# 3. Deploy to target paths
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-deploy.sh deploy
```

### Daily Workflow

```bash
# 1. Edit at target location
vim .cursor/rules/formatting/markdown.mdc

# 2. Check status (from anywhere)
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh status

# 3. Commit and push
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh sync "Update markdown rules"
```

### Updating from Remote

```bash
cd .sharables
./scripts/sharables-pull.sh
```

## Benefits

1. **Custom Paths** - Put sections exactly where you want them
2. **Git Tracking** - Source control knows where code came from
3. **Symlink Magic** - Files appear at target but tracked in repo
4. **Easy Updates** - Pull once, use everywhere
5. **Flexible Config** - YAML config for easy customization

## Configuration Options

### Method: symlink (Recommended)
- Files appear at target location
- Changes tracked in sharables repo
- Single source of truth

### Method: copy
- Independent copies
- No git tracking
- Use for read-only reference

## Documentation

- **Complete Guide**: `Sharables-Monorepo-Guide.md`
- **Deployment Guide**: `Sharables-Deployment-Guide.md`
- **Quick Reference**: `Sharables-Quick-Reference.md`
- **Example Config**: `Sharables-Example-Config.yaml`

## Summary

You now have a system where:
- ✅ Sections can be deployed to **any path you specify**
- ✅ Git **tracks the source** (sharables repo)
- ✅ Changes at target locations are **tracked in the repo**
- ✅ Pushing goes to the **sharables repository**
- ✅ Everything is **configuration-driven** via YAML

The "cut and paste" happens via symlinks - files appear at your target locations, but they're actually in the sharables repo, so git knows exactly where they came from and where to push them.

