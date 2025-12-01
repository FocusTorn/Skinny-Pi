#!/bin/bash
# Setup script for creating and managing a "Sharables" monorepo
# This allows selective pull/push of different sections using sparse checkout

set -e

REPO_NAME="${1:-sharables}"
GITHUB_USER="${2:-}"
REMOTE_URL=""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Sharables Monorepo Setup ===${NC}\n"

# Function to check if we're in a git repo
is_git_repo() {
    git rev-parse --git-dir > /dev/null 2>&1
}

# Function to initialize or use existing repo
setup_repo() {
    if [ -d "$REPO_NAME" ]; then
        echo -e "${YELLOW}Directory $REPO_NAME already exists.${NC}"
        read -p "Use existing directory? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Exiting..."
            exit 1
        fi
        cd "$REPO_NAME"
    else
        mkdir -p "$REPO_NAME"
        cd "$REPO_NAME"
        git init
        echo -e "${GREEN}Initialized new git repository${NC}"
    fi

    # Enable sparse checkout
    git config core.sparseCheckout true
    
    # Create initial structure
    mkdir -p .git/info
    touch .git/info/sparse-checkout
    
    echo -e "${GREEN}Sparse checkout enabled${NC}"
}

# Function to create initial structure
create_structure() {
    echo -e "\n${BLUE}Creating monorepo structure...${NC}"
    
    # Create directory structure
    mkdir -p cursor-rules/{formatting,workspace}
    mkdir -p global-utilities/{scripts,helpers}
    mkdir -p shared-configs
    mkdir -p docs
    mkdir -p scripts  # Helper scripts (always available)
    
    # Create README
    cat > README.md << 'EOF'
# Sharables - Shared Resources Monorepo

A monorepo for shared configurations, utilities, and resources that can be used across multiple projects.

## Structure

```
sharables/
├── scripts/             # Helper scripts (always available)
│   ├── sharables-checkout.sh
│   ├── sharables-push.sh
│   └── sharables-pull.sh
├── cursor-rules/        # Cursor IDE rules and configurations
│   ├── formatting/      # Formatting rules
│   └── workspace/       # Workspace architecture rules
├── global-utilities/    # Shared scripts and utilities
│   ├── scripts/         # Reusable scripts
│   └── helpers/         # Helper functions
├── shared-configs/      # Shared configuration files
└── docs/                # Documentation
```

## Usage

### Initial Setup (First Time)

1. **Clone with sparse checkout:**
   ```bash
   git clone --filter=blob:none --sparse <repo-url> sharables
   cd sharables
   ```

2. **Checkout specific sections:**
   ```bash
   # Checkout cursor-rules only
   ./scripts/sharables-checkout.sh cursor-rules
   
   # Checkout multiple sections
   ./scripts/sharables-checkout.sh cursor-rules global-utilities
   
   # Checkout everything
   ./scripts/sharables-checkout.sh '/*'
   ```

### Adding Sections

1. **Add files to a section:**
   ```bash
   # Add files to cursor-rules
   git add cursor-rules/
   git commit -m "Add cursor rules"
   ```

2. **Push specific section:**
   ```bash
   git push origin main
   ```

### Updating Sections

```bash
# Update only cursor-rules
./scripts/sharables-checkout.sh cursor-rules
./scripts/sharables-pull.sh

# Update all sections
./scripts/sharables-checkout.sh '/*'
./scripts/sharables-pull.sh
```

## Helper Scripts

Use the helper scripts in `scripts/` (always available, even with sparse checkout):

**Cross-Platform (Python):**
- `sharables-deploy.py` - Deploy sections to target paths (Windows & Linux)
- `sharables-git-helper.py` - Git operations helper (Windows & Linux)

**Linux/Debian (Bash):**
- `sharables-checkout.sh` - Checkout specific sections
- `sharables-push.sh` - Push changes with section validation
- `sharables-pull.sh` - Pull updates for checked-out sections
- `sharables-deploy.sh` - Deploy sections (wrapper, uses Python if available)

## Sections

### cursor-rules
Cursor IDE rules and configurations that can be shared across projects.

### global-utilities
Reusable scripts and helper functions.

### shared-configs
Shared configuration files (git configs, editor configs, etc.)

## Contributing

1. Checkout the section you want to modify
2. Make your changes
3. Commit and push
4. Other projects can pull just that section
EOF

    # Create .gitignore
    cat > .gitignore << 'EOF'
# OS
.DS_Store
Thumbs.db
*.swp
*.swo
*~

# IDE
.idea/
.vscode/
*.code-workspace

# Temporary files
*.tmp
*.bak
*.log
EOF

    # Create initial sparse checkout config
    # Helper scripts are in root scripts/ directory (always available)
    cat > .git/info/sparse-checkout << 'EOF'
# Sparse checkout patterns
# Helper scripts in scripts/ are always available (root level)
scripts/
README.md
.gitignore
# Add more patterns as needed:
# cursor-rules/
# global-utilities/
# shared-configs/
EOF
    
    echo -e "${GREEN}Structure created${NC}"
}

# Function to setup GitHub remote
setup_remote() {
    if [ -z "$GITHUB_USER" ]; then
        read -p "GitHub username/organization: " GITHUB_USER
    fi
    
    REMOTE_URL="git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
    
    # Check if remote already exists
    if git remote get-url origin > /dev/null 2>&1; then
        echo -e "${YELLOW}Remote 'origin' already exists: $(git remote get-url origin)${NC}"
        read -p "Update to $REMOTE_URL? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git remote set-url origin "$REMOTE_URL"
            echo -e "${GREEN}Remote updated${NC}"
        fi
    else
        git remote add origin "$REMOTE_URL"
        echo -e "${GREEN}Remote added: $REMOTE_URL${NC}"
    fi
}

# Function to create helper scripts
create_helpers() {
    echo -e "\n${BLUE}Creating helper scripts...${NC}"
    
    # Helper scripts go in root scripts/ directory so they're always available
    mkdir -p scripts
    
    # Checkout helper (in root scripts/ so always available)
    cat > scripts/sharables-checkout.sh << 'SCRIPT_EOF'
#!/bin/bash
# Checkout specific sections of the sharables monorepo

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <section1> [section2] ..."
    echo ""
    echo "Available sections:"
    echo "  cursor-rules"
    echo "  global-utilities"
    echo "  shared-configs"
    echo ""
    echo "Examples:"
    echo "  $0 cursor-rules"
    echo "  $0 cursor-rules global-utilities"
    echo "  $0 '/*'  # Checkout everything"
    exit 1
fi

# Enable sparse checkout if not already
git config core.sparseCheckout true

# Build sparse checkout patterns
PATTERNS=()
for section in "$@"; do
    # Add section with trailing slash to match directory
    if [ "$section" != "/*" ]; then
        PATTERNS+=("$section/")
        PATTERNS+=("$section/**")
    else
        PATTERNS+=("/*")
    fi
done

# Set sparse checkout
printf "%s\n" "${PATTERNS[@]}" > .git/info/sparse-checkout

# Read the sparse checkout file
git sparse-checkout reapply

echo "Checked out sections: $*"
echo "Files available:"
git ls-files | head -20
SCRIPT_EOF

    # Push helper (in root scripts/ so always available)
    cat > scripts/sharables-push.sh << 'SCRIPT_EOF'
#!/bin/bash
# Push changes with section validation

set -e

BRANCH="${1:-main}"

echo "Checking for changes..."
if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to push"
    exit 0
fi

echo "Staged changes:"
git diff --cached --name-only

read -p "Push to origin/$BRANCH? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 1
fi

git push origin "$BRANCH"
echo "Pushed successfully"
SCRIPT_EOF

    # Pull helper (in root scripts/ so always available)
    cat > scripts/sharables-pull.sh << 'SCRIPT_EOF'
#!/bin/bash
# Pull updates for checked-out sections

set -e

BRANCH="${1:-main}"

echo "Pulling updates from origin/$BRANCH..."
git pull origin "$BRANCH"

echo "Updated sections:"
git sparse-checkout list
SCRIPT_EOF

    # Deploy helper (in root scripts/ so always available)
    # Copy Python version for cross-platform support
    if [ -f "/root/_playground/_scripts/sharables-deploy.py" ]; then
        cp /root/_playground/_scripts/sharables-deploy.py scripts/
        chmod +x scripts/sharables-deploy.py
    fi
    
    if [ -f "/root/_playground/_scripts/sharables-git-helper.py" ]; then
        cp /root/_playground/_scripts/sharables-git-helper.py scripts/
        chmod +x scripts/sharables-git-helper.py
    fi
    
    # Also create bash wrapper for Linux users
    cat > scripts/sharables-deploy.sh << 'SCRIPT_EOF'
#!/bin/bash
# Deploy sections to target paths (wrapper - uses Python if available, falls back to bash)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Try Python version first (cross-platform)
if [ -f "$SCRIPT_DIR/sharables-deploy.py" ]; then
    python3 "$SCRIPT_DIR/sharables-deploy.py" "$@"
    exit $?
fi

# Fallback to _playground version
if [ -f "/root/_playground/_scripts/sharables-deploy.sh" ]; then
    SHARABLES_DIR="$REPO_ROOT" /root/_playground/_scripts/sharables-deploy.sh "$@"
else
    echo "Error: sharables-deploy script not found"
    exit 1
fi
SCRIPT_EOF

    chmod +x scripts/*.sh scripts/*.py 2>/dev/null || chmod +x scripts/*.sh
    
    echo -e "${GREEN}Helper scripts created${NC}"
}

# Main execution
main() {
    setup_repo
    create_structure
    create_helpers
    
    echo -e "\n${BLUE}Setup GitHub remote?${NC}"
    read -p "Set up remote now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_remote
    fi
    
    echo -e "\n${GREEN}=== Setup Complete ===${NC}\n"
    echo "Next steps:"
    echo "1. Add files to the appropriate sections"
    echo "2. Commit: git add . && git commit -m 'Initial commit'"
    if [ -n "$REMOTE_URL" ]; then
        echo "3. Create repo on GitHub: $REMOTE_URL"
        echo "4. Push: git push -u origin main"
    else
        echo "3. Set up remote: git remote add origin <repo-url>"
        echo "4. Push: git push -u origin main"
    fi
    echo ""
    echo "To checkout specific sections in other projects:"
    echo "  git clone --filter=blob:none --sparse <repo-url> sharables"
    echo "  cd sharables"
    echo "  ./global-utilities/scripts/sharables-checkout.sh cursor-rules"
}

main "$@"

