# Sharables Deployment Guide

## Overview

The deployment system allows you to:
- **Deploy sections to custom paths** (e.g., `.cursor/rules`, `~/.local/share/sharables`)
- **Maintain git tracking** - Changes at target locations are tracked in the sharables repo
- **Use symlinks** - Files appear at target locations but are actually in the sharables repo

## Quick Start

### 1. Clone Sharables Repo

```bash
# In your project root
git clone --filter=blob:none --sparse git@github.com:user/sharables.git .sharables
cd .sharables
./scripts/sharables-checkout.sh cursor-rules global-utilities
```

### 2. Create Deployment Config

```bash
# Create config file
cd .sharables
./scripts/sharables-deploy.sh config

# Edit the config
vim .sharables-deploy.yaml
```

Example config:

```yaml
# Sharables Deployment Configuration
deployments:
  # Deploy cursor-rules to .cursor/rules (relative to project root)
  - section: cursor-rules
    target: .cursor/rules
    method: symlink
    
  # Deploy global-utilities to home directory
  - section: global-utilities
    target: ~/.local/share/sharables
    method: symlink
```

### 3. Deploy Sections

```bash
# Deploy according to config
./scripts/sharables-deploy.sh deploy

# Or use the helper from _playground
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-deploy.sh deploy
```

This will:
- Create symlinks from target paths to the sharables repo
- Make files appear at target locations
- Maintain git tracking in the sharables repo

## How It Works

### Symlink Method (Recommended)

```
Project Root/
├── .sharables/              # Git repo
│   └── cursor-rules/        # Actual files
│       └── formatting/
└── .cursor/
    └── rules -> ../.sharables/cursor-rules  # Symlink
```

**Benefits:**
- ✅ Changes at `.cursor/rules` are tracked in `.sharables/`
- ✅ Git operations work from `.sharables/`
- ✅ Single source of truth
- ✅ No duplication

### Copy Method

```
Project Root/
├── .sharables/              # Git repo
│   └── cursor-rules/        # Source files
└── .cursor/
    └── rules/                # Copied files (not tracked)
```

**Note:** Copy method doesn't maintain git connection. Use only if you need independent copies.

## Working with Deployed Sections

### Making Changes

1. **Edit files at target location:**
   ```bash
   # Edit at the symlinked location
   vim .cursor/rules/formatting/markdown.mdc
   ```

2. **Changes are tracked in sharables repo:**
   ```bash
   cd .sharables
   git status
   # Shows changes to cursor-rules/
   ```

3. **Commit and push:**
   ```bash
   cd .sharables
   git add cursor-rules/
   git commit -m "Update markdown formatting rules"
   git push origin main
   ```

### Using Git Helper

The git helper script makes this easier:

```bash
# From anywhere in your project
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh status

# Commit changes
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh commit "Update cursor rules"

# Push
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh push

# Or do both
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh sync "Update from project"
```

## Configuration Examples

### Example 1: Cursor Rules Only

```yaml
deployments:
  - section: cursor-rules
    target: .cursor/rules
    method: symlink
```

### Example 2: Multiple Sections

```yaml
deployments:
  - section: cursor-rules
    target: .cursor/rules
    method: symlink
    
  - section: global-utilities
    target: ~/.local/share/sharables
    method: symlink
    
  - section: shared-configs
    target: .config/sharables
    method: symlink
```

### Example 3: Absolute Paths

```yaml
deployments:
  - section: cursor-rules
    target: /home/user/.cursor/rules
    method: symlink
```

### Example 4: Mixed Methods

```yaml
deployments:
  # Symlink for active development
  - section: cursor-rules
    target: .cursor/rules
    method: symlink
    
  # Copy for read-only reference
  - section: docs
    target: .sharables-docs
    method: copy
```

## Deployment Commands

### Deploy

```bash
# Deploy all sections from config
./scripts/sharables-deploy.sh deploy

# Or with full path
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-deploy.sh deploy
```

### Undeploy

```bash
# Remove all deployed sections
./scripts/sharables-deploy.sh undeploy
```

### Create Config

```bash
# Generate example config
./scripts/sharables-deploy.sh config
```

## Git Workflow

### Standard Workflow

1. **Make changes** at target location (e.g., `.cursor/rules/`)
2. **Check status** in sharables repo:
   ```bash
   cd .sharables
   git status
   ```
3. **Commit**:
   ```bash
   git add cursor-rules/
   git commit -m "Update cursor rules"
   ```
4. **Push**:
   ```bash
   git push origin main
   ```

### Using Git Helper

```bash
# Quick status check
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh status

# Commit specific section
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh commit "Update cursor rules" cursor-rules

# Push changes
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh push

# One-step sync
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh sync "Update from project"
```

## Troubleshooting

### Symlink Points to Wrong Location

```bash
# Check symlink target
ls -la .cursor/rules

# Redeploy
cd .sharables
./scripts/sharables-deploy.sh undeploy
./scripts/sharables-deploy.sh deploy
```

### Target Already Exists

The deploy script will:
- Ask if you want to replace existing symlinks
- Backup non-symlink files before replacing
- Skip if you decline

### Changes Not Showing in Git

```bash
# Make sure you're in the sharables repo
cd .sharables

# Check if files are tracked
git status

# If symlink is broken, redeploy
./scripts/sharables-deploy.sh deploy
```

### Finding Sharables Directory

The git helper can auto-detect:

```bash
# From anywhere in project
/root/_playground/_scripts/sharables-git-helper.sh status
# Will find .sharables or sharables directory automatically
```

## Best Practices

### 1. Use Symlinks for Active Development
- Changes are immediately tracked
- Single source of truth
- Easy to update

### 2. Use Copy for Read-Only Reference
- When you need independent copies
- For documentation or examples
- When symlinks might cause issues

### 3. Keep Config in Sharables Repo
- Commit `.sharables-deploy.yaml` to the sharables repo
- Share deployment configs across projects
- Version control your deployment setup

### 4. Use Git Helper for Convenience
- Faster workflow
- Less chance of errors
- Clear status information

### 5. Document Target Paths
- Add comments in config file
- Document why each path was chosen
- Keep paths consistent across projects

## Advanced Usage

### Custom Deployment Script

You can create project-specific deployment scripts:

```bash
#!/bin/bash
# deploy-sharables.sh

SHARABLES_DIR=".sharables"

# Checkout needed sections
cd "$SHARABLES_DIR"
./scripts/sharables-checkout.sh cursor-rules global-utilities

# Deploy
SHARABLES_DIR="$SHARABLES_DIR" /root/_playground/_scripts/sharables-deploy.sh deploy

echo "Sharables deployed!"
```

### Integration with Bootstrap Scripts

Add to your project bootstrap:

```bash
# In bootstrap script
if [ ! -d ".sharables" ]; then
    git clone --filter=blob:none --sparse <repo-url> .sharables
    cd .sharables
    ./scripts/sharables-checkout.sh cursor-rules
    SHARABLES_DIR=".sharables" /root/_playground/_scripts/sharables-deploy.sh deploy
fi
```

## Summary

The deployment system provides:
- ✅ **Flexible paths** - Deploy sections anywhere
- ✅ **Git tracking** - Changes tracked in sharables repo
- ✅ **Symlink support** - Files appear at target locations
- ✅ **Easy workflow** - Helper scripts for common operations
- ✅ **Configuration-driven** - YAML config for deployment mapping

This allows you to have your `.cursor` rules, utilities, and configs exactly where you want them, while maintaining centralized version control in the sharables monorepo.

