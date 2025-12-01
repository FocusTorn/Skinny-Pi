# Sharables Monorepo Guide

## Overview

The **Sharables** monorepo is a centralized repository for shared resources that can be used across multiple projects. It uses **Git Sparse Checkout** to allow selective pulling and pushing of different sections.

## Why Sparse Checkout?

- **Selective Updates**: Pull only the sections you need
- **Reduced Clutter**: Don't download everything if you only need cursor rules
- **Independent Development**: Work on one section without pulling others
- **Single Source of Truth**: All shared resources in one place

## Repository Structure

```
sharables/
├── cursor-rules/           # Cursor IDE rules and configurations
│   ├── formatting/        # Formatting rules (markdown, code, etc.)
│   └── workspace/         # Workspace architecture rules
├── global-utilities/      # Shared scripts and utilities
│   ├── scripts/           # Reusable scripts
│   │   ├── sharables-checkout.sh
│   │   ├── sharables-push.sh
│   │   └── sharables-pull.sh
│   └── helpers/           # Helper functions and libraries
├── shared-configs/        # Shared configuration files
│   ├── .gitconfig         # Git configurations
│   ├── .editorconfig      # Editor configurations
│   └── shell/              # Shell configs (zsh, bash, etc.)
└── docs/                   # Documentation
```

## Setup

### 1. Create the Repository

```bash
# Run the setup script
_playground/_scripts/setup-sharables-repo.sh sharables your-github-username

# Or manually:
mkdir sharables && cd sharables
git init
git config core.sparseCheckout true
```

### 2. Add Initial Content

```bash
# Copy your .cursor rules
cp -r /.cursor/rules/* cursor-rules/

# Copy global utilities
cp -r _playground/_scripts/* global-utilities/scripts/

# Add and commit
git add .
git commit -m "Initial commit: Add cursor rules and utilities"
```

### 3. Push to GitHub

```bash
# Create repo on GitHub first, then:
git remote add origin git@github.com:your-username/sharables.git
git branch -M main
git push -u origin main
```

## Usage in Projects

### Initial Clone (Sparse Checkout)

```bash
# Clone with sparse checkout enabled
git clone --filter=blob:none --sparse git@github.com:your-username/sharables.git
cd sharables

# Checkout only cursor-rules
./scripts/sharables-checkout.sh cursor-rules

# Or checkout multiple sections
./scripts/sharables-checkout.sh cursor-rules global-utilities
```

### Using in Existing Projects

#### Option 1: Symlink Approach (Recommended)

```bash
# In your project root
git clone --filter=blob:none --sparse git@github.com:your-username/sharables.git .sharables
cd .sharables
./scripts/sharables-checkout.sh cursor-rules

# Create symlink to cursor rules
cd ..
ln -s .sharables/cursor-rules .cursor/rules
```

#### Option 2: Direct Copy

```bash
# Clone and checkout
git clone --filter=blob:none --sparse git@github.com:your-username/sharables.git .sharables
cd .sharables
./scripts/sharables-checkout.sh cursor-rules

# Copy to project
cp -r cursor-rules/* ../.cursor/rules/
```

#### Option 3: Git Submodule (Alternative)

```bash
# Add as submodule
git submodule add git@github.com:your-username/sharables.git .sharables
cd .sharables
git sparse-checkout set cursor-rules
```

## Working with Sections

### Checkout Specific Sections

```bash
# Single section
./scripts/sharables-checkout.sh cursor-rules

# Multiple sections
./scripts/sharables-checkout.sh cursor-rules global-utilities

# Everything
./scripts/sharables-checkout.sh '/*'
```

### View Current Checkout

```bash
git sparse-checkout list
```

### Add New Section

```bash
# Create new section directory
mkdir -p new-section

# Add files
# ... add your files ...

# Update sparse checkout to include it
echo "new-section/" >> .git/info/sparse-checkout
git sparse-checkout reapply

# Commit
git add new-section/
git commit -m "Add new-section"
```

### Push Changes

```bash
# Use helper script
./scripts/sharables-push.sh

# Or manually
git add .
git commit -m "Update cursor-rules"
git push origin main
```

### Pull Updates

```bash
# Use helper script
./scripts/sharables-pull.sh

# Or manually
git pull origin main
```

## Section Guidelines

### cursor-rules/
- **Purpose**: Cursor IDE rules and configurations
- **Structure**: Mirror `.cursor/rules/` structure
- **Usage**: Symlink or copy to `.cursor/rules/` in projects

### global-utilities/
- **Purpose**: Reusable scripts and helper functions
- **Structure**: 
  - `scripts/` - Executable scripts
  - `helpers/` - Source files, libraries, functions
- **Usage**: Add to PATH or symlink to `~/.local/bin/`

### shared-configs/
- **Purpose**: Shared configuration files
- **Structure**: Organized by tool/application
- **Usage**: Copy or symlink to appropriate locations

## Best Practices

### 1. Section Independence
- Each section should be self-contained
- Avoid cross-section dependencies when possible
- Document dependencies if they exist

### 2. Versioning
- Use semantic versioning for major changes
- Tag releases: `git tag -a v1.0.0 -m "Release v1.0.0"`
- Document breaking changes

### 3. Documentation
- Each section should have a README
- Document usage, dependencies, and examples
- Keep docs in sync with code

### 4. Testing
- Test changes in a project before pushing
- Verify sparse checkout works correctly
- Test on fresh clones

### 5. Commit Messages
- Use clear, descriptive messages
- Reference section: `[cursor-rules] Update formatting rules`
- Group related changes together

## Migration from Existing Setup

### Migrating .cursor Rules

```bash
# In sharables repo
cd sharables

# Copy rules
cp -r /.cursor/rules/* cursor-rules/

# Organize by category
mkdir -p cursor-rules/formatting
mkdir -p cursor-rules/workspace

# Move files appropriately
mv cursor-rules/*.mdc cursor-rules/formatting/  # If they're formatting rules
# etc.

# Commit
git add cursor-rules/
git commit -m "Migrate cursor rules from local setup"
```

### Migrating Global Utilities

```bash
# Copy scripts
cp -r _playground/_scripts/* global-utilities/scripts/

# Clean up project-specific scripts
# Keep only truly global utilities

# Commit
git add global-utilities/
git commit -m "Migrate global utilities"
```

## Troubleshooting

### Sparse Checkout Not Working

```bash
# Re-enable sparse checkout
git config core.sparseCheckout true

# Reapply
git sparse-checkout reapply
```

### Files Not Showing Up

```bash
# Check what's actually checked out
git sparse-checkout list

# Verify files exist in repo
git ls-tree -r HEAD --name-only | grep <section>

# Reapply sparse checkout
git sparse-checkout reapply
```

### Merge Conflicts

```bash
# If conflicts occur during pull
git pull origin main

# Resolve conflicts normally
# Then reapply sparse checkout
git sparse-checkout reapply
```

## Advanced Usage

### Custom Sparse Checkout Patterns

Edit `.git/info/sparse-checkout` directly:

```
# Include entire section
cursor-rules/

# Include specific subdirectory
global-utilities/scripts/

# Exclude pattern (use !)
/*
!unwanted-section/
```

### Multiple Remotes

```bash
# Add additional remote
git remote add upstream git@github.com:other-user/sharables.git

# Pull from upstream
git pull upstream main
```

### Branching Strategy

```bash
# Create section-specific branch
git checkout -b cursor-rules-update

# Make changes
# ...

# Merge back to main
git checkout main
git merge cursor-rules-update
```

## Integration with Projects

### Automated Setup Script

Create a bootstrap script in your project:

```bash
#!/bin/bash
# bootstrap-sharables.sh

SHARABLES_DIR=".sharables"
SHARABLES_REPO="git@github.com:your-username/sharables.git"

if [ ! -d "$SHARABLES_DIR" ]; then
    git clone --filter=blob:none --sparse "$SHARABLES_REPO" "$SHARABLES_DIR"
    cd "$SHARABLES_DIR"
    ./scripts/sharables-checkout.sh cursor-rules
    cd ..
fi

# Symlink cursor rules
if [ ! -d ".cursor/rules" ]; then
    mkdir -p .cursor
    ln -s "../$SHARABLES_DIR/cursor-rules" .cursor/rules
fi
```

## Examples

### Example 1: Using in New Project

```bash
# Create new project
mkdir my-project && cd my-project
git init

# Clone sharables
git clone --filter=blob:none --sparse git@github.com:user/sharables.git .sharables
cd .sharables
./global-utilities/scripts/sharables-checkout.sh cursor-rules
cd ..

# Link cursor rules
mkdir -p .cursor
ln -s ../.sharables/cursor-rules .cursor/rules
```

### Example 2: Updating Cursor Rules

```bash
# In sharables repo
cd .sharables
./scripts/sharables-checkout.sh cursor-rules

# Edit rules
vim cursor-rules/formatting/markdown.mdc

# Commit and push
git add cursor-rules/
git commit -m "[cursor-rules] Update markdown formatting"
./scripts/sharables-push.sh
```

### Example 3: Adding New Utility

```bash
# In sharables repo
cd .sharables
./scripts/sharables-checkout.sh global-utilities

# Add new script
cat > global-utilities/scripts/my-utility.sh << 'EOF'
#!/bin/bash
echo "My utility"
EOF
chmod +x global-utilities/scripts/my-utility.sh

# Commit
git add global-utilities/
git commit -m "[global-utilities] Add my-utility script"
git push origin main
```

## Summary

The Sharables monorepo provides:
- ✅ Centralized shared resources
- ✅ Selective checkout (only what you need)
- ✅ Independent section development
- ✅ Easy updates across projects
- ✅ Single source of truth

Use sparse checkout to manage which sections are available in each project, keeping your workspace clean and focused.

