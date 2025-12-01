#!/bin/bash
# Git helper for working with sharables from deployed locations
# Helps you commit/push changes made at target locations back to the sharables repo

set -e

SHARABLES_DIR="${SHARABLES_DIR:-.sharables}"
CONFIG_FILE="${SHARABLES_DIR}/.sharables-deploy.yaml"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ACTION="${1:-status}"

# Find sharables directory (could be .sharables or ../sharables, etc.)
find_sharables_dir() {
    local current="$PWD"
    while [ "$current" != "/" ]; do
        if [ -d "$current/.sharables" ] && [ -d "$current/.sharables/.git" ]; then
            echo "$current/.sharables"
            return 0
        fi
        if [ -d "$current/sharables" ] && [ -d "$current/sharables/.git" ]; then
            echo "$current/sharables"
            return 0
        fi
        current="$(dirname "$current")"
    done
    return 1
}

# Auto-detect sharables directory if not set
if [ ! -d "$SHARABLES_DIR" ] || [ ! -d "$SHARABLES_DIR/.git" ]; then
    DETECTED=$(find_sharables_dir)
    if [ -n "$DETECTED" ]; then
        SHARABLES_DIR="$DETECTED"
    fi
fi

if [ ! -d "$SHARABLES_DIR" ] || [ ! -d "$SHARABLES_DIR/.git" ]; then
    echo -e "${RED}Sharables directory not found: $SHARABLES_DIR${NC}"
    echo "Set SHARABLES_DIR environment variable or run from a project with sharables"
    exit 1
fi

cd "$SHARABLES_DIR"

# Function to show status
show_status() {
    echo -e "${BLUE}=== Sharables Git Status ===${NC}\n"
    
    echo -e "${GREEN}Repository:${NC} $(pwd)"
    echo -e "${GREEN}Remote:${NC} $(git remote get-url origin 2>/dev/null || echo 'not set')"
    echo -e "${GREEN}Branch:${NC} $(git branch --show-current)"
    echo ""
    
    echo -e "${BLUE}Checked out sections:${NC}"
    git sparse-checkout list 2>/dev/null || echo "  (sparse checkout not configured)"
    echo ""
    
    echo -e "${BLUE}Changes:${NC}"
    if [ -n "$(git status --porcelain)" ]; then
        git status --short
    else
        echo "  No changes"
    fi
    echo ""
    
    # Show deployed locations if config exists
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${BLUE}Deployed locations:${NC}"
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*target:[[:space:]]*(.+)$ ]]; then
                local target="${BASH_REMATCH[1]}"
                target=$(echo "$target" | sed "s|^~|$HOME|")
                if [ -L "$target" ] || [ -e "$target" ]; then
                    if [ -L "$target" ]; then
                        echo -e "  ${GREEN}✓${NC} $target (symlink)"
                    else
                        echo -e "  ${YELLOW}○${NC} $target (exists)"
                    fi
                fi
            fi
        done < "$CONFIG_FILE"
    fi
}

# Function to commit changes
commit_changes() {
    local message="${2:-Update sharables}"
    local section="${3:-}"
    
    if [ -z "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}No changes to commit${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Staging changes...${NC}"
    if [ -n "$section" ]; then
        git add "$section/"
        echo -e "${GREEN}Staged: $section/${NC}"
    else
        git add .
    fi
    
    echo -e "${BLUE}Committing...${NC}"
    git commit -m "$message"
    
    echo -e "${GREEN}✓ Committed${NC}"
}

# Function to push changes
push_changes() {
    local branch="${2:-$(git branch --show-current)}"
    
    if [ -z "$(git log origin/$branch..HEAD 2>/dev/null)" ]; then
        echo -e "${YELLOW}No commits to push${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Pushing to origin/$branch...${NC}"
    git push origin "$branch"
    
    echo -e "${GREEN}✓ Pushed${NC}"
}

# Function to show what changed in deployed locations
show_deployed_changes() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}No deployment config found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== Changes in Deployed Locations ===${NC}\n"
    
    local current_section=""
    local current_target=""
    
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*section:[[:space:]]*(.+)$ ]]; then
            current_section="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]*target:[[:space:]]*(.+)$ ]]; then
            current_target="${BASH_REMATCH[1]}"
            
            if [ -n "$current_section" ] && [ -n "$current_target" ]; then
                target=$(echo "$current_target" | sed "s|^~|$HOME|")
                
                if [ -L "$target" ]; then
                    local link_target=$(readlink -f "$target")
                    if [[ "$link_target" == *"$current_section"* ]]; then
                        echo -e "${GREEN}$current_section${NC} -> $target"
                        
                        # Check for changes
                        cd "$(dirname "$link_target")"
                        if [ -n "$(git -C "$SHARABLES_DIR" status --porcelain "$current_section/")" ]; then
                            echo -e "  ${YELLOW}Has uncommitted changes${NC}"
                            git -C "$SHARABLES_DIR" diff --stat "$current_section/" | head -5
                        fi
                        echo ""
                    fi
                fi
                
                current_section=""
                current_target=""
            fi
        fi
    done < "$CONFIG_FILE"
}

# Main execution
case "$ACTION" in
    status)
        show_status
        ;;
    commit)
        commit_changes "$@"
        ;;
    push)
        push_changes "$@"
        ;;
    deploy-changes)
        show_deployed_changes
        ;;
    sync)
        # Commit and push in one go
        commit_changes "$@"
        push_changes "$@"
        ;;
    *)
        echo "Usage: $0 [status|commit|push|sync|deploy-changes]"
        echo ""
        echo "Commands:"
        echo "  status          - Show git status and deployed locations"
        echo "  commit [msg]    - Commit changes (optionally for specific section)"
        echo "  push [branch]   - Push changes to remote"
        echo "  sync [msg]      - Commit and push in one go"
        echo "  deploy-changes  - Show changes in deployed locations"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 commit 'Update cursor rules'"
        echo "  $0 commit 'Update cursor rules' cursor-rules"
        echo "  $0 push"
        echo "  $0 sync 'Update from project'"
        exit 1
        ;;
esac

