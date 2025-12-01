#!/bin/bash
# Setup script for using .cursor as a Git submodule
# Simpler approach if you only need cursor rules

set -e

CURSOR_REPO_URL="${1:-}"
PROJECT_DIR="${2:-.}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Setup .cursor as Git Submodule ===${NC}\n"

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}Not in a git repository. Initializing...${NC}"
    git init
fi

# Check if .cursor already exists
if [ -d ".cursor" ] && [ -d ".cursor/.git" ]; then
    echo -e "${YELLOW}.cursor already exists as a submodule${NC}"
    read -p "Update it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    git submodule update --remote .cursor
    exit 0
fi

# If .cursor exists but isn't a submodule
if [ -d ".cursor" ]; then
    echo -e "${YELLOW}.cursor directory exists but isn't a submodule${NC}"
    read -p "Backup and convert to submodule? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv .cursor .cursor.backup
        echo -e "${GREEN}Backed up to .cursor.backup${NC}"
    else
        echo "Exiting..."
        exit 1
    fi
fi

# Get repo URL if not provided
if [ -z "$CURSOR_REPO_URL" ]; then
    echo "Enter the cursor-rules repository URL:"
    echo "  Example: git@github.com:your-username/cursor-rules.git"
    read -p "URL: " CURSOR_REPO_URL
fi

if [ -z "$CURSOR_REPO_URL" ]; then
    echo -e "${RED}Repository URL required${NC}"
    exit 1
fi

# Add as submodule
echo -e "\n${BLUE}Adding .cursor as submodule...${NC}"
git submodule add "$CURSOR_REPO_URL" .cursor

echo -e "\n${GREEN}✓ .cursor added as submodule${NC}\n"

echo -e "${BLUE}Usage:${NC}"
echo "  # Update cursor rules"
echo "  cd .cursor"
echo "  git pull origin main"
echo "  cd .."
echo "  git add .cursor"
echo "  git commit -m 'Update cursor rules'"
echo ""
echo "  # Clone project with submodule"
echo "  git clone --recurse-submodules <your-project-url>"
echo ""
echo "  # Initialize submodule in existing clone"
echo "  git submodule init"
echo "  git submodule update"


