#!/bin/bash
# Setup script for sharables repo with submodules
# Creates sharables as main repo with cursor-rules, global-utilities as submodules

set -e

SHARABLES_DIR="${1:-sharables}"
CURSOR_REPO="${2:-}"
UTILITIES_REPO="${3:-}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Setup Sharables with Submodules ===${NC}\n"

# Create or use existing sharables directory
if [ -d "$SHARABLES_DIR" ]; then
    echo -e "${YELLOW}Directory $SHARABLES_DIR already exists${NC}"
    read -p "Use existing? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    cd "$SHARABLES_DIR"
else
    mkdir -p "$SHARABLES_DIR"
    cd "$SHARABLES_DIR"
    git init
    echo -e "${GREEN}Initialized sharables repository${NC}"
fi

# Check if already has submodules
if [ -f ".gitmodules" ]; then
    echo -e "${YELLOW}.gitmodules already exists${NC}"
    cat .gitmodules
    read -p "Add more submodules? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Done. Existing submodules:"
        git submodule status
        exit 0
    fi
fi

# Get cursor-rules repo URL
if [ -z "$CURSOR_REPO" ]; then
    echo ""
    echo "Enter cursor-rules repository URL (or press Enter to skip):"
    echo "  Example: git@github.com:your-username/cursor-rules.git"
    read -p "URL: " CURSOR_REPO
fi

# Add cursor-rules submodule
if [ -n "$CURSOR_REPO" ]; then
    if [ -d "cursor-rules" ]; then
        echo -e "${YELLOW}cursor-rules already exists${NC}"
    else
        echo -e "\n${BLUE}Adding cursor-rules submodule...${NC}"
        git submodule add "$CURSOR_REPO" cursor-rules
        echo -e "${GREEN}✓ Added cursor-rules submodule${NC}"
    fi
fi

# Get global-utilities repo URL
if [ -z "$UTILITIES_REPO" ]; then
    echo ""
    echo "Enter global-utilities repository URL (or press Enter to skip):"
    echo "  Example: git@github.com:your-username/global-utilities.git"
    read -p "URL: " UTILITIES_REPO
fi

# Add global-utilities submodule
if [ -n "$UTILITIES_REPO" ]; then
    if [ -d "global-utilities" ]; then
        echo -e "${YELLOW}global-utilities already exists${NC}"
    else
        echo -e "\n${BLUE}Adding global-utilities submodule...${NC}"
        git submodule add "$UTILITIES_REPO" global-utilities
        echo -e "${GREEN}✓ Added global-utilities submodule${NC}"
    fi
fi

# Create deployment config
if [ ! -f ".sharables-deploy.yaml" ]; then
    echo -e "\n${BLUE}Creating deployment config...${NC}"
    cat > .sharables-deploy.yaml << 'EOF'
# Sharables Deployment Configuration
# Maps submodules to target paths

deployments:
  # Deploy cursor-rules submodule to .cursor/rules
  - section: cursor-rules
    target: .cursor/rules
    method: symlink
    
  # Deploy global-utilities submodule to home directory
  - section: global-utilities
    target: ~/.local/share/sharables
    method: symlink
EOF
    echo -e "${GREEN}✓ Created deployment config${NC}"
fi

# Create README
if [ ! -f "README.md" ]; then
    cat > README.md << 'EOF'
# Sharables - Shared Resources with Submodules

This repository contains shared resources as Git submodules.

## Structure

```
sharables/
├── cursor-rules/        # Submodule: Cursor IDE rules
├── global-utilities/   # Submodule: Shared utilities
└── .gitmodules         # Submodule configuration
```

## Setup

```bash
# Clone with submodules
git clone --recurse-submodules <repo-url> sharables

# Or initialize after clone
git submodule init
git submodule update
```

## Usage

### Work with Submodules

```bash
# Update a submodule
cd cursor-rules
git pull origin main
cd ..
git add cursor-rules
git commit -m "Update cursor-rules"
```

### Deploy to Custom Paths

```bash
# Deploy submodules to target paths
python3 ../_playground/_scripts/sharables-deploy.py deploy
```

## Submodules

- **cursor-rules**: Cursor IDE rules and configurations
- **global-utilities**: Shared scripts and utilities
EOF
    echo -e "${GREEN}✓ Created README${NC}"
fi

# Show status
echo -e "\n${GREEN}=== Setup Complete ===${NC}\n"
echo "Submodules:"
git submodule status 2>/dev/null || echo "  (none yet)"

echo ""
echo "Next steps:"
echo "1. Create remote repositories for each submodule"
echo "2. Push submodules to their remotes"
echo "3. Commit and push sharables repo:"
echo "   git add .gitmodules .sharables-deploy.yaml README.md"
echo "   git commit -m 'Add submodules'"
echo "   git remote add origin <sharables-repo-url>"
echo "   git push -u origin main"
echo ""
echo "To use in projects:"
echo "  git clone --recurse-submodules <sharables-repo-url> .sharables"
echo "  cd .sharables"
echo "  python3 ../_playground/_scripts/sharables-deploy.py deploy"


