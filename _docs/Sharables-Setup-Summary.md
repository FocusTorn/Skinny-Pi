# Sharables Monorepo - Setup Summary

## What Was Created

A complete monorepo setup system for shared resources that can be selectively pulled/pushed across multiple projects.

## Files Created

### Setup Scripts
- **`_playground/_scripts/setup-sharables-repo.sh`** - Creates and initializes the sharables monorepo
- **`_playground/_scripts/migrate-to-sharables.sh`** - Migrates existing content (`.cursor` rules, utilities) into the repo

### Documentation
- **`_playground/_docs/Sharables-Monorepo-Guide.md`** - Complete guide with examples
- **`_playground/_docs/Sharables-Quick-Reference.md`** - Quick command reference
- **`_playground/_docs/Sharables-Setup-Summary.md`** - This file

## Quick Start

### 1. Create the Repository

```bash
# Create and initialize the repo
_playground/_scripts/setup-sharables-repo.sh sharables your-github-username

# This will:
# - Create directory structure
# - Initialize git repo
# - Enable sparse checkout
# - Create helper scripts
# - Set up GitHub remote (optional)
```

### 2. Migrate Existing Content

```bash
# Dry run first (see what would be migrated)
_playground/_scripts/migrate-to-sharables.sh ../sharables --dry-run

# Actually migrate
_playground/_scripts/migrate-to-sharables.sh ../sharables
```

### 3. Commit and Push

```bash
cd sharables
git add .
git commit -m "Initial commit: Add cursor rules and utilities"
git push -u origin main
```

## Repository Structure

```
sharables/
├── scripts/                    # Helper scripts (always available)
│   ├── sharables-checkout.sh   # Checkout specific sections
│   ├── sharables-push.sh       # Push changes
│   └── sharables-pull.sh       # Pull updates
├── cursor-rules/               # Cursor IDE rules
│   ├── formatting/            # Formatting rules
│   └── workspace/             # Workspace rules
├── global-utilities/          # Shared scripts
│   ├── scripts/               # Reusable scripts
│   └── helpers/               # Helper functions
├── shared-configs/            # Configuration files
└── docs/                      # Documentation
```

## How It Works

### Sparse Checkout
- Git feature that allows checking out only specific directories
- Allows selective pulling/pushing of sections
- Helper scripts in `scripts/` are always available (root level)

### Usage in Projects

```bash
# Clone with sparse checkout
git clone --filter=blob:none --sparse git@github.com:user/sharables.git .sharables
cd .sharables

# Checkout only what you need
./scripts/sharables-checkout.sh cursor-rules

# Link to your project
cd ..
mkdir -p .cursor
ln -s ../.sharables/cursor-rules .cursor/rules
```

## Key Features

✅ **Selective Checkout** - Only pull sections you need  
✅ **Independent Sections** - Work on one section without others  
✅ **Always-Available Helpers** - Scripts in root `scripts/` directory  
✅ **Easy Migration** - Script to move existing content  
✅ **Cross-Project Sharing** - Use same rules/configs everywhere  

## Next Steps

1. **Create the repo** using the setup script
2. **Migrate your content** (`.cursor` rules, utilities, etc.)
3. **Push to GitHub**
4. **Use in projects** by cloning with sparse checkout
5. **Update as needed** - changes sync across all projects

## Documentation

- Full guide: `_playground/_docs/Sharables-Monorepo-Guide.md`
- Quick reference: `_playground/_docs/Sharables-Quick-Reference.md`

## Benefits

- **Single Source of Truth** - All shared resources in one place
- **Version Control** - Track changes to shared configs
- **Selective Updates** - Only pull what you need
- **Easy Maintenance** - Update once, use everywhere
- **Clean Workspaces** - Don't clutter projects with unused sections

