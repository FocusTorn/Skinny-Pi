#!/bin/bash
# Setup multiple submodules directly to their destination directories
# No wrapper repo needed - each section goes where it belongs

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Setup Multiple Direct Submodules ===${NC}\n"

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}Not in a git repository. Initializing...${NC}"
    git init
fi

# Get repository URLs
echo "Enter repository URLs (press Enter to skip):"
echo ""

# Cursor rules
read -p "Cursor rules repo URL: " CURSOR_REPO
if [ -n "$CURSOR_REPO" ]; then
    if [ -d ".cursor" ]; then
        echo -e "${YELLOW}.cursor already exists${NC}"
    else
        echo -e "${BLUE}Adding cursor-rules submodule to .cursor...${NC}"
        git submodule add "$CURSOR_REPO" .cursor
        echo -e "${GREEN}✓ Added cursor-rules to .cursor${NC}"
    fi
fi

# Global utilities
read -p "Global utilities repo URL: " UTILITIES_REPO
if [ -n "$UTILITIES_REPO" ]; then
    TARGET=".local/share/sharables"
    if [ -d "$TARGET" ]; then
        echo -e "${YELLOW}$TARGET already exists${NC}"
    else
        echo -e "${BLUE}Adding global-utilities submodule to $TARGET...${NC}"
        mkdir -p "$(dirname "$TARGET")"
        git submodule add "$UTILITIES_REPO" "$TARGET"
        echo -e "${GREEN}✓ Added global-utilities to $TARGET${NC}"
    fi
fi

# Shared configs
read -p "Shared configs repo URL: " CONFIGS_REPO
if [ -n "$CONFIGS_REPO" ]; then
    TARGET=".config/sharables"
    if [ -d "$TARGET" ]; then
        echo -e "${YELLOW}$TARGET already exists${NC}"
    else
        echo -e "${BLUE}Adding shared-configs submodule to $TARGET...${NC}"
        mkdir -p "$(dirname "$TARGET")"
        git submodule add "$CONFIGS_REPO" "$TARGET"
        echo -e "${GREEN}✓ Added shared-configs to $TARGET${NC}"
    fi
fi

# Show status
echo -e "\n${GREEN}=== Setup Complete ===${NC}\n"
echo "Submodules:"
git submodule status 2>/dev/null || echo "  (none added)"

echo ""
echo "Next steps:"
echo "1. Review .gitmodules file"
echo "2. Commit submodules:"
echo "   git add .gitmodules"
echo "   git commit -m 'Add sharables submodules'"
echo "   git push"
echo ""
echo "To clone with submodules:"
echo "  git clone --recurse-submodules <your-project-url>"
echo ""
echo "To update submodules:"
echo "  git submodule update --remote"
echo ""
echo "To work with a submodule:"
echo "  cd .cursor  # or other submodule directory"
echo "  git pull"
echo "  # Edit files"
echo "  git commit -m 'Update'"
echo "  git push"
echo "  cd .."
echo "  git add .cursor"
echo "  git commit -m 'Update cursor rules'"


