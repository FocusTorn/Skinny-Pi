#!/usr/bin/env bash
# Setup git-crypt for encrypting secrets in the repository
# This allows .secrets to be stored in git securely

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$HOME/_playground"
GIT_ATTRIBUTES="$REPO_ROOT/.gitattributes"
SECRETS_FILE="$HOME/.secrets"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

error() { echo -e "${RED}❌ $1${NC}" >&2; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Check if git-crypt is installed
check_git_crypt() {
    if ! command -v git-crypt &> /dev/null; then
        error "git-crypt is not installed"
        echo ""
        echo "Install with:"
        echo "  Debian/Ubuntu: sudo apt install git-crypt"
        echo "  Or build from source: https://github.com/AGWA/git-crypt"
        exit 1
    fi
    success "git-crypt is installed"
}

# Initialize git-crypt in repository
init_git_crypt() {
    cd "$REPO_ROOT"
    
    if [ ! -d ".git" ]; then
        error "Not a git repository. Run 'git init' first."
        exit 1
    fi
    
    # Check if already initialized
    if git-crypt status &>/dev/null; then
        warning "git-crypt is already initialized"
        read -p "Re-initialize? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    info "Initializing git-crypt..."
    git-crypt init
    success "git-crypt initialized"
}

# Create .gitattributes file
setup_gitattributes() {
    cd "$REPO_ROOT"
    
    info "Setting up .gitattributes..."
    
    # Create or update .gitattributes
    if [ ! -f ".gitattributes" ]; then
        cat > ".gitattributes" << 'EOF'
# Encrypted files with git-crypt
.secrets filter=git-crypt diff=git-crypt
*.secrets filter=git-crypt diff=git-crypt
EOF
        success "Created .gitattributes"
    else
        # Check if .secrets is already configured
        if grep -q "^\.secrets" ".gitattributes" 2>/dev/null; then
            warning ".secrets already configured in .gitattributes"
        else
            # Add .secrets to .gitattributes
            cat >> ".gitattributes" << 'EOF'

# Encrypted files with git-crypt
.secrets filter=git-crypt diff=git-crypt
*.secrets filter=git-crypt diff=git-crypt
EOF
            success "Added .secrets to .gitattributes"
        fi
    fi
}

# Update .gitignore to allow encrypted .secrets
update_gitignore() {
    cd "$REPO_ROOT"
    
    info "Updating .gitignore..."
    
    if [ ! -f ".gitignore" ]; then
        error ".gitignore not found"
        return 1
    fi
    
    # Remove .secrets from .gitignore (we want to track the encrypted version)
    if grep -q "^\.secrets$" ".gitignore" 2>/dev/null; then
        # Create backup
        cp ".gitignore" ".gitignore.bak"
        # Remove .secrets line
        sed -i '/^\.secrets$/d' ".gitignore"
        success "Removed .secrets from .gitignore (encrypted version will be tracked)"
        info "Backup saved to .gitignore.bak"
    else
        info ".secrets not in .gitignore (or already removed)"
    fi
    
    # Add comment about encrypted secrets
    if ! grep -q "# Encrypted .secrets is tracked" ".gitignore" 2>/dev/null; then
        cat >> ".gitignore" << 'EOF'

# Note: .secrets is encrypted with git-crypt and IS tracked in git
# The encrypted version is safe to commit
EOF
        success "Added note about encrypted .secrets"
    fi
}

# Copy secrets file to repo (if it exists)
copy_secrets_to_repo() {
    cd "$REPO_ROOT"
    
    REPO_SECRETS="$REPO_ROOT/.secrets"
    
    if [ -f "$SECRETS_FILE" ]; then
        info "Copying $SECRETS_FILE to repository..."
        cp "$SECRETS_FILE" "$REPO_SECRETS"
        chmod 600 "$REPO_SECRETS"
        success "Copied secrets file to repository"
        warning "The file will be encrypted when you commit it"
    else
        warning "Secrets file not found at $SECRETS_FILE"
        info "Creating template .secrets file in repository..."
        
        cat > "$REPO_SECRETS" << 'EOF'
# Unified Secrets File
# This file is encrypted with git-crypt
# Add your passwords/keys here
# 
# Format: KEY=VALUE (one per line)
# Comments start with #

# ============================================
# MQTT Broker
# ============================================
MQTT_PASSWORD=
MQTT_USERNAME=mqtt

# ============================================
# GitHub (if needed)
# ============================================
# GITHUB_TOKEN=

# ============================================
# Other APIs / Services
# ============================================
# API_KEY_SERVICE1=
# API_KEY_SERVICE2=
EOF
        chmod 600 "$REPO_SECRETS"
        success "Created template .secrets file"
        warning "Edit $REPO_SECRETS and add your secrets before committing"
    fi
}

# Show status and next steps
show_status() {
    cd "$REPO_ROOT"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 git-crypt Setup Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check git-crypt status
    if git-crypt status &>/dev/null; then
        success "git-crypt is initialized"
        echo ""
        info "Encrypted files:"
        git-crypt status | grep -E "^    " | sed 's/^/  /' || echo "  (none yet)"
    else
        warning "git-crypt not initialized"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Next Steps"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. Edit .secrets file (if needed):"
    echo "   nano $REPO_ROOT/.secrets"
    echo ""
    echo "2. Add and commit the encrypted file:"
    echo "   cd $REPO_ROOT"
    echo "   git add .gitattributes .secrets"
    echo "   git commit -m 'Add encrypted .secrets with git-crypt'"
    echo ""
    echo "3. Push to GitHub:"
    echo "   git push origin main"
    echo ""
    echo "4. On other machines, unlock the repository:"
    echo "   git-crypt unlock"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔑 Managing git-crypt Keys"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Export key (for other machines):"
    echo "   git-crypt export-key ~/git-crypt-key"
    echo ""
    echo "Import key (on other machine):"
    echo "   git-crypt unlock ~/git-crypt-key"
    echo ""
    echo "⚠️  IMPORTANT: Store the exported key securely!"
    echo "   The key allows decryption of all secrets."
    echo ""
}

# Main execution
main() {
    echo "🔐 Setting up git-crypt for secrets encryption..."
    echo ""
    
    check_git_crypt
    echo ""
    
    init_git_crypt
    echo ""
    
    setup_gitattributes
    echo ""
    
    update_gitignore
    echo ""
    
    copy_secrets_to_repo
    echo ""
    
    show_status
}

# Run main
main

