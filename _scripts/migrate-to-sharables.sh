#!/bin/bash
# Migration script to move existing content into sharables repo

set -e

SHARABLES_DIR="${1:-../sharables}"
DRY_RUN="${2:-}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Migrate to Sharables ===${NC}\n"

# Check if sharables directory exists
if [ ! -d "$SHARABLES_DIR" ]; then
    echo -e "${RED}Sharables directory not found: $SHARABLES_DIR${NC}"
    echo "Create it first with: _playground/_scripts/setup-sharables-repo.sh"
    exit 1
fi

cd "$SHARABLES_DIR"

# Ensure we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Not a git repository: $SHARABLES_DIR${NC}"
    exit 1
fi

# Enable sparse checkout
git config core.sparseCheckout true

# Function to copy with dry-run support
safe_copy() {
    local src="$1"
    local dst="$2"
    local desc="$3"
    
    if [ -n "$DRY_RUN" ]; then
        echo -e "${YELLOW}[DRY RUN] Would copy: $src -> $dst${NC}"
        if [ -d "$src" ]; then
            echo "  Contents: $(find "$src" -type f | wc -l) files"
        fi
    else
        if [ -d "$src" ]; then
            mkdir -p "$dst"
            cp -r "$src"/* "$dst/" 2>/dev/null || true
            echo -e "${GREEN}Copied $desc${NC}"
        elif [ -f "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
            echo -e "${GREEN}Copied $desc${NC}"
        else
            echo -e "${YELLOW}Skipping (not found): $src${NC}"
        fi
    fi
}

# Migrate .cursor rules
echo -e "\n${BLUE}1. Migrating .cursor rules...${NC}"
if [ -d "/.cursor/rules" ]; then
    # Checkout cursor-rules section
    echo "cursor-rules/" > .git/info/sparse-checkout
    echo "cursor-rules/**" >> .git/info/sparse-checkout
    git sparse-checkout reapply 2>/dev/null || true
    
    # Organize rules
    mkdir -p cursor-rules/formatting
    mkdir -p cursor-rules/workspace
    
    # Copy formatting rules
    if [ -d "/.cursor/rules/formatting" ]; then
        safe_copy "/.cursor/rules/formatting" "cursor-rules/formatting" "formatting rules"
    fi
    
    # Copy workspace rules
    if [ -f "/.cursor/rules/workspace-architecture.mdc" ]; then
        safe_copy "/.cursor/rules/workspace-architecture.mdc" "cursor-rules/workspace/workspace-architecture.mdc" "workspace architecture rule"
    fi
    
    # Copy other rules
    for file in /.cursor/rules/*.mdc; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            safe_copy "$file" "cursor-rules/$filename" "rule: $filename"
        fi
    done
else
    echo -e "${YELLOW}No .cursor/rules directory found${NC}"
fi

# Migrate global utilities
echo -e "\n${BLUE}2. Migrating global utilities...${NC}"
if [ -d "/root/_playground/_scripts" ]; then
    # Checkout global-utilities section
    echo "global-utilities/" >> .git/info/sparse-checkout
    echo "global-utilities/**" >> .git/info/sparse-checkout
    git sparse-checkout reapply 2>/dev/null || true
    
    mkdir -p global-utilities/scripts
    
    # Copy scripts (excluding project-specific ones)
    for script in /root/_playground/_scripts/*.sh; do
        if [ -f "$script" ]; then
            scriptname=$(basename "$script")
            # Skip project-specific scripts
            if [[ ! "$scriptname" =~ ^(bootstrap-|setup-).* ]]; then
                safe_copy "$script" "global-utilities/scripts/$scriptname" "script: $scriptname"
            fi
        fi
    done
    
    # Copy script directories
    if [ -d "/root/_playground/_scripts/Colors" ]; then
        safe_copy "/root/_playground/_scripts/Colors" "global-utilities/scripts/Colors" "Colors scripts"
    fi
    
    if [ -d "/root/_playground/_scripts/mqtt" ]; then
        safe_copy "/root/_playground/_scripts/mqtt" "global-utilities/scripts/mqtt" "MQTT scripts"
    fi
else
    echo -e "${YELLOW}No _playground/_scripts directory found${NC}"
fi

# Migrate shared configs
echo -e "\n${BLUE}3. Migrating shared configs...${NC}"
mkdir -p shared-configs

# Copy git config if exists
if [ -f "$HOME/.gitconfig" ]; then
    safe_copy "$HOME/.gitconfig" "shared-configs/.gitconfig" "git config"
fi

# Copy editor config if exists
if [ -f "/root/_playground/.editorconfig" ]; then
    safe_copy "/root/_playground/.editorconfig" "shared-configs/.editorconfig" "editor config"
fi

# Summary
    # Create default deployment config
    if [ -z "$DRY_RUN" ] && [ ! -f ".sharables-deploy.yaml" ]; then
        echo -e "\n${BLUE}Creating default deployment config...${NC}"
        cat > .sharables-deploy.yaml << 'EOF'
# Sharables Deployment Configuration
# Maps sections to target paths (relative to project root)

deployments:
  # Deploy cursor-rules to .cursor/rules
  - section: cursor-rules
    target: .cursor/rules
    method: symlink  # symlink, copy, or git-worktree
    
  # Deploy global-utilities to ~/.local/share/sharables
  - section: global-utilities
    target: ~/.local/share/sharables
    method: symlink
EOF
        echo -e "${GREEN}Created default deployment config${NC}"
    fi

    echo -e "\n${GREEN}=== Migration Summary ===${NC}\n"

if [ -n "$DRY_RUN" ]; then
    echo -e "${YELLOW}DRY RUN - No files were actually copied${NC}"
    echo "Run without --dry-run to perform migration"
else
    echo "Files migrated. Next steps:"
    echo "1. Review changes: git status"
    echo "2. Add files: git add ."
    echo "3. Commit: git commit -m 'Migrate content from local setup'"
    echo "4. Push: git push origin main"
    echo ""
    echo "To deploy in projects:"
    echo "  git clone --filter=blob:none --sparse <repo-url> .sharables"
    echo "  cd .sharables"
    echo "  ./scripts/sharables-checkout.sh cursor-rules global-utilities"
    echo "  SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-deploy.sh deploy"
fi

echo ""
echo "Deployment config created at: .sharables-deploy.yaml"
echo "Edit it to customize target paths for each section"

