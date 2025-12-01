#!/bin/bash
# Deploy sharables sections to target paths while maintaining git tracking
# Uses symlinks to keep the connection to the source repo

set -e

SHARABLES_DIR="${SHARABLES_DIR:-.sharables}"
CONFIG_FILE="${SHARABLES_DIR}/.sharables-deploy.yaml"
ACTION="${1:-deploy}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if sharables directory exists
if [ ! -d "$SHARABLES_DIR" ]; then
    echo -e "${RED}Sharables directory not found: $SHARABLES_DIR${NC}"
    echo "Clone the sharables repo first:"
    echo "  git clone --filter=blob:none --sparse <repo-url> $SHARABLES_DIR"
    exit 1
fi

cd "$SHARABLES_DIR"

# Function to create example config
create_example_config() {
    cat > "$CONFIG_FILE" << 'EOF'
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
    
  # Example: Deploy shared-configs to multiple locations
  # - section: shared-configs
  #   target: .config/sharables
  #   method: symlink
EOF
}

# Check if config exists
if [ ! -f "$CONFIG_FILE" ] && [ "$ACTION" != "config" ]; then
    echo -e "${YELLOW}Config file not found: $CONFIG_FILE${NC}"
    echo "Creating example config..."
    create_example_config
    echo -e "${GREEN}Created example config. Edit it and run again.${NC}"
    exit 0
fi

# Function to deploy a section
deploy_section() {
    local section="$1"
    local target="$2"
    local method="${3:-symlink}"
    local project_root="${4:-..}"
    
    # Expand ~ in target path
    target=$(echo "$target" | sed "s|^~|$HOME|")
    
    # Make target absolute if relative
    if [[ "$target" != /* ]]; then
        target="$(cd "$project_root" && pwd)/$target"
    fi
    
    local source_path="$(pwd)/$section"
    
    # Check if section exists
    if [ ! -d "$source_path" ]; then
        echo -e "${YELLOW}Section not found: $section (skipping)${NC}"
        return 1
    fi
    
    # Check if target exists
    if [ -e "$target" ]; then
        if [ -L "$target" ]; then
            local link_target=$(readlink "$target")
            if [ "$link_target" = "$source_path" ]; then
                echo -e "${GREEN}✓ Already deployed: $section -> $target${NC}"
                return 0
            else
                echo -e "${YELLOW}Target exists but points elsewhere: $target${NC}"
                read -p "Replace? (y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    return 1
                fi
                rm "$target"
            fi
        else
            echo -e "${YELLOW}Target exists (not a symlink): $target${NC}"
            read -p "Backup and replace? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
            mv "$target" "${target}.backup.$(date +%s)"
        fi
    fi
    
    # Create parent directory
    mkdir -p "$(dirname "$target")"
    
    # Deploy based on method
    case "$method" in
        symlink)
            ln -s "$source_path" "$target"
            echo -e "${GREEN}✓ Deployed (symlink): $section -> $target${NC}"
            ;;
        copy)
            cp -r "$source_path" "$target"
            echo -e "${GREEN}✓ Deployed (copy): $section -> $target${NC}"
            echo -e "${YELLOW}  Note: Copy method doesn't maintain git connection${NC}"
            ;;
        git-worktree)
            # Use git worktree for independent git tracking
            echo -e "${YELLOW}Git worktree method not yet implemented${NC}"
            return 1
            ;;
        *)
            echo -e "${RED}Unknown method: $method${NC}"
            return 1
            ;;
    esac
}

# Function to undeploy a section
undeploy_section() {
    local section="$1"
    local target="$2"
    
    # Expand ~ in target path
    target=$(echo "$target" | sed "s|^~|$HOME|")
    
    if [ -L "$target" ]; then
        rm "$target"
        echo -e "${GREEN}✓ Removed: $target${NC}"
    elif [ -e "$target" ]; then
        echo -e "${YELLOW}Target exists but is not a symlink: $target${NC}"
        read -p "Remove anyway? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$target"
            echo -e "${GREEN}✓ Removed: $target${NC}"
        fi
    else
        echo -e "${YELLOW}Target not found: $target${NC}"
    fi
}

# Parse YAML config (simple parser)
parse_config() {
    local current_section=""
    local current_target=""
    local current_method="symlink"
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Check for deployment entry
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*section:[[:space:]]*(.+)$ ]]; then
            current_section="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]*target:[[:space:]]*(.+)$ ]]; then
            current_target="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]*method:[[:space:]]*(.+)$ ]]; then
            current_method="${BASH_REMATCH[1]}"
        fi
        
        # If we have all three, process it
        if [ -n "$current_section" ] && [ -n "$current_target" ]; then
            if [ "$ACTION" = "deploy" ]; then
                deploy_section "$current_section" "$current_target" "$current_method" ".."
            elif [ "$ACTION" = "undeploy" ]; then
                undeploy_section "$current_section" "$current_target"
            fi
            # Reset for next entry
            current_section=""
            current_target=""
            current_method="symlink"
        fi
    done < "$CONFIG_FILE"
}

# Main execution
case "$ACTION" in
    deploy)
        echo -e "${BLUE}=== Deploying Sharables Sections ===${NC}\n"
        parse_config
        echo -e "\n${GREEN}Deployment complete!${NC}"
        echo ""
        echo "Git operations:"
        echo "  - Edit files at their target locations (they're symlinked)"
        echo "  - Commit/push from: $SHARABLES_DIR"
        echo "  - Changes are tracked in the sharables repo"
        ;;
    undeploy)
        echo -e "${BLUE}=== Undeploying Sharables Sections ===${NC}\n"
        parse_config
        echo -e "\n${GREEN}Undeployment complete!${NC}"
        ;;
    config)
        create_example_config
        echo -e "${GREEN}Created example config at: $CONFIG_FILE${NC}"
        ;;
    *)
        echo "Usage: $0 [deploy|undeploy|config]"
        echo ""
        echo "Commands:"
        echo "  deploy   - Deploy sections according to config"
        echo "  undeploy - Remove deployed sections"
        echo "  config   - Create example config file"
        exit 1
        ;;
esac

