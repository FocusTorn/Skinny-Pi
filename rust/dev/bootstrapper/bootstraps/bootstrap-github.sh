#!/usr/bin/env bash
# Bootstrap GitHub SSH authentication setup for system restore
# Creates SSH key for GitHub authentication and configures Git to use SSH

set -e

SSH_KEY_PATH="$HOME/.ssh/github_pi"
SSH_CONFIG="$HOME/.ssh/config"
GIT_EMAIL="${GIT_EMAIL:-$(git config --global user.email 2>/dev/null || echo 'user@example.com')}"
GIT_REPO_DIR="$HOME/_playground"

# Show help by default
show_help() {
    cat << EOF
GitHub SSH Bootstrap Script

Usage: $0 [command]

Commands:
  setup              Full setup: SSH key, config, and git remote
  status             Show current status (key, remotes, repo, etc.)
  remove-key         Remove SSH key
  remove-remote      Remove/detach from git remote(s)
  remove-repo        Remove local git repository (.git directory)
  help               Show this help

Examples:
  $0 setup           # Full setup
  $0 status          # Show current status
  $0 remove-key      # Remove SSH key
  $0 remove-remote   # Remove git remotes
  $0 remove-repo     # Remove local git repo
EOF
}

# Show status
show_status() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 GitHub SSH Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # SSH Key Status
    echo "🔑 SSH Key:"
    if [ -f "$SSH_KEY_PATH" ]; then
        echo "  ✅ Key exists: $SSH_KEY_PATH"
        KEY_PERMS=$(stat -c "%a" "$SSH_KEY_PATH" 2>/dev/null || stat -f "%OLp" "$SSH_KEY_PATH" 2>/dev/null || echo "unknown")
        if [ "$KEY_PERMS" = "600" ]; then
            echo "  ✅ Permissions: $KEY_PERMS (correct)"
        else
            echo "  ⚠️  Permissions: $KEY_PERMS (should be 600)"
        fi
        if [ -f "$SSH_KEY_PATH.pub" ]; then
            echo "  ✅ Public key exists"
            echo "  📋 Public key fingerprint:"
            ssh-keygen -lf "$SSH_KEY_PATH.pub" 2>/dev/null | sed 's/^/     /' || echo "     (could not read)"
        else
            echo "  ⚠️  Public key missing"
        fi
    else
        echo "  ❌ Key not found: $SSH_KEY_PATH"
    fi
    echo ""
    
    # SSH Config Status
    echo "⚙️  SSH Config:"
    if [ -f "$SSH_CONFIG" ]; then
        if grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
            echo "  ✅ GitHub config present in $SSH_CONFIG"
            echo "  📋 Config:"
            grep -A 4 "Host github.com" "$SSH_CONFIG" | sed 's/^/     /'
        else
            echo "  ⚠️  GitHub config not found in $SSH_CONFIG"
        fi
    else
        echo "  ⚠️  SSH config file not found: $SSH_CONFIG"
    fi
    echo ""
    
    # Local Git Repository Status
    echo "📂 Local Git Repository:"
    if [ -d "$GIT_REPO_DIR/.git" ]; then
        echo "  ✅ Repository exists: $GIT_REPO_DIR"
        cd "$GIT_REPO_DIR"
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
        echo "  📋 Current branch: $CURRENT_BRANCH"
        
        # Local commit info
        if git rev-parse HEAD &>/dev/null; then
            LAST_COMMIT=$(git log -1 --oneline 2>/dev/null | head -1)
            echo "  📋 Last commit: $LAST_COMMIT"
        else
            echo "  ⚠️  No commits yet"
        fi
        
        # Local branch info
        LOCAL_BRANCHES=$(git branch 2>/dev/null | wc -l)
        echo "  📋 Local branches: $LOCAL_BRANCHES"
    else
        echo "  ❌ No git repository found at $GIT_REPO_DIR"
    fi
    echo ""
    
    # Remote Git Repository Status
    echo "🌐 Remote Git Repository:"
    if [ -d "$GIT_REPO_DIR/.git" ]; then
        cd "$GIT_REPO_DIR"
        REMOTES=$(git remote)
        if [ -n "$REMOTES" ]; then
            for REMOTE in $REMOTES; do
                REMOTE_URL=$(git remote get-url "$REMOTE" 2>/dev/null)
                echo "  📋 Remote '$REMOTE': $REMOTE_URL"
                
                # Check if remote is reachable
                if git ls-remote "$REMOTE" &>/dev/null; then
                    echo "     ✅ Remote is reachable"
                else
                    echo "     ⚠️  Remote is not reachable"
                fi
            done
            
            # Upstream tracking
            if git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
                UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
                echo "  📋 Upstream tracking: $UPSTREAM"
            else
                echo "  ⚠️  No upstream branch configured"
            fi
        else
            echo "  ⚠️  No remotes configured"
        fi
    else
        echo "  ⚠️  No local repository (cannot check remotes)"
    fi
    echo ""
    
    # GitHub SSH Connection Test
    echo "🔌 GitHub SSH Connection:"
    if [ -f "$SSH_KEY_PATH" ]; then
        TEST_OUTPUT=$(timeout 5 ssh -o ConnectTimeout=5 -o BatchMode=yes -T git@github.com 2>&1)
        EXIT_CODE=$?
        
        if echo "$TEST_OUTPUT" | grep -qi "successfully authenticated"; then
            echo "  ✅ SSH connection successful"
            GITHUB_USER=$(echo "$TEST_OUTPUT" | grep -oP "(?<=Hi )\w+" || echo "unknown")
            echo "  📋 Authenticated as: $GITHUB_USER"
        elif echo "$TEST_OUTPUT" | grep -qi "permission denied"; then
            echo "  ⚠️  Permission denied (key may not be added to GitHub)"
            echo "     Add key at: https://github.com/settings/keys"
        elif echo "$TEST_OUTPUT" | grep -qi "host key verification failed"; then
            echo "  ⚠️  Host key verification failed"
            echo "     Run: ssh-keyscan github.com >> ~/.ssh/known_hosts"
        elif [ $EXIT_CODE -eq 124 ]; then
            echo "  ⚠️  Connection test timed out"
            echo "     Check network connectivity"
        else
            echo "  ⚠️  Connection test failed (exit code: $EXIT_CODE)"
            if [ -n "$TEST_OUTPUT" ]; then
                echo "     Output: $(echo "$TEST_OUTPUT" | head -1)"
            fi
            echo "     Run manually: ssh -T git@github.com"
        fi
    else
        echo "  ⚠️  Cannot test (SSH key not found)"
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Setup local git repository
setup_local_repo() {
    if [ -d "$GIT_REPO_DIR/.git" ]; then
        echo "✅ Local git repository already exists at $GIT_REPO_DIR"
        return 0
    fi
    
    echo "📂 Setting up local git repository..."
    mkdir -p "$GIT_REPO_DIR"
    cd "$GIT_REPO_DIR"
    
    # Initialize git repository
    git init
    echo "✅ Git repository initialized"
    
    # Set default branch to main
    git branch -M main 2>/dev/null || git checkout -b main 2>/dev/null
    
    # Configure git user if not set
    if ! git config user.name &>/dev/null; then
        GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
        if [ -z "$GIT_NAME" ]; then
            read -p "Enter your name for git commits: " GIT_NAME
            git config user.name "$GIT_NAME"
            git config --global user.name "$GIT_NAME"
        else
            git config user.name "$GIT_NAME"
        fi
    fi
    
    if ! git config user.email &>/dev/null; then
        GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
        if [ -z "$GIT_EMAIL" ]; then
            read -p "Enter your email for git commits: " GIT_EMAIL
            git config user.email "$GIT_EMAIL"
            git config --global user.email "$GIT_EMAIL"
        else
            git config user.email "$GIT_EMAIL"
        fi
    fi
    
    echo "✅ Local git repository configured"
}

# Setup git remote
setup_remote() {
    cd "$GIT_REPO_DIR"
    
    # Check if remotes already exist
    REMOTES=$(git remote 2>/dev/null)
    if [ -n "$REMOTES" ]; then
        echo "📋 Existing remotes found:"
        git remote -v
        echo ""
        read -p "Remove existing remotes and set up new one? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for REMOTE in $REMOTES; do
                git remote remove "$REMOTE"
                echo "✅ Removed remote: $REMOTE"
            done
        else
            echo "ℹ️  Keeping existing remotes"
            return 0
        fi
    fi
    
    # Get GitHub username
    GITHUB_USER=$(git config --global user.name 2>/dev/null || echo "")
    if [ -z "$GITHUB_USER" ]; then
        read -p "Enter your GitHub username: " GITHUB_USER
        if [ -z "$GITHUB_USER" ]; then
            echo "⚠️  No username provided, skipping remote setup"
            return 1
        fi
    else
        echo "ℹ️  Detected GitHub username: $GITHUB_USER"
        read -p "Is this correct? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            read -p "Enter your GitHub username: " GITHUB_USER
        fi
    fi
    
    # Prompt for repository name
    DEFAULT_REPO="Skinny-Pi"
    read -p "Enter repository name [$DEFAULT_REPO]: " REPO_NAME
    REPO_NAME="${REPO_NAME:-$DEFAULT_REPO}"
    
    # Add remote
    REMOTE_URL="git@github.com:$GITHUB_USER/$REPO_NAME.git"
    git remote add origin "$REMOTE_URL"
    echo "✅ Added remote 'origin': $REMOTE_URL"
    
    # Set upstream branch
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    echo "🔧 Setting upstream branch to origin/$CURRENT_BRANCH"
    git branch --set-upstream-to=origin/$CURRENT_BRANCH 2>/dev/null || echo "⚠️  Upstream will be set on first push"
    
    echo ""
    echo "📋 Current remotes:"
    git remote -v
    echo ""
    echo "📝 Next steps:"
    echo "   1. Create the repository on GitHub: https://github.com/new"
    echo "      Name: $REPO_NAME"
    echo "      Don't initialize with README (we already have one)"
    echo ""
    echo "   2. Push to GitHub:"
    echo "      git add ."
    echo "      git commit -m 'Initial $REPO_NAME repository setup'"
    echo "      git push -u origin $CURRENT_BRANCH"
}

# Handle subcommands
case "${1:-help}" in
    setup)
        # Full setup - continue to main script
        SETUP_LOCAL_REPO=true
        SETUP_REMOTE=true
        ;;
    status)
        show_status
        exit 0
        ;;
    remove-key|delete-key)
        if [ -f "$SSH_KEY_PATH" ] || [ -f "$SSH_KEY_PATH.pub" ]; then
            echo "⚠️  WARNING: This will remove the SSH key at $SSH_KEY_PATH"
            read -p "Are you sure? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -f "$SSH_KEY_PATH" "$SSH_KEY_PATH.pub"
                echo "✅ SSH key removed"
                echo "   Note: You may want to remove it from GitHub: https://github.com/settings/keys"
            else
                echo "❌ Cancelled"
            fi
        else
            echo "ℹ️  No SSH key found at $SSH_KEY_PATH"
        fi
        exit 0
        ;;
    remove-remote|detach-remote)
        if [ -d "$GIT_REPO_DIR/.git" ]; then
            cd "$GIT_REPO_DIR"
            REMOTES=$(git remote)
            if [ -n "$REMOTES" ]; then
                echo "📋 Current remotes:"
                git remote -v
                echo ""
                read -p "Remove all remotes? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    for REMOTE in $REMOTES; do
                        git remote remove "$REMOTE"
                        echo "✅ Removed remote: $REMOTE"
                    done
                    echo "✅ All remotes removed"
                else
                    echo "❌ Cancelled"
                fi
            else
                echo "ℹ️  No remotes configured"
            fi
        else
            echo "ℹ️  No git repository found at $GIT_REPO_DIR"
        fi
        exit 0
        ;;
    remove-repo|delete-repo)
        if [ -d "$GIT_REPO_DIR/.git" ]; then
            echo "⚠️  WARNING: This will remove the git repository at $GIT_REPO_DIR"
            echo "   This will NOT delete your files, only the .git directory"
            read -p "Are you sure? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$GIT_REPO_DIR/.git"
                echo "✅ Git repository removed from $GIT_REPO_DIR"
                echo "   Your files are still intact"
            else
                echo "❌ Cancelled"
            fi
        else
            echo "ℹ️  No git repository found at $GIT_REPO_DIR"
        fi
        exit 0
        ;;
    help|--help|-h|"")
        show_help
        exit 0
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

echo "🔑 Bootstrapping GitHub SSH authentication..."

# Setup local repository if needed
if [ "${SETUP_LOCAL_REPO:-false}" = "true" ]; then
    setup_local_repo
    echo ""
fi

# Check if SSH key already exists
if [ -f "$SSH_KEY_PATH" ]; then
    echo "⚠️  SSH key already exists at $SSH_KEY_PATH"
    read -p "Recreate SSH key? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "ℹ️  Skipping SSH key generation"
    else
        echo "🗑️  Removing existing key..."
        rm -f "$SSH_KEY_PATH" "$SSH_KEY_PATH.pub"
    fi
fi

# Generate SSH key if it doesn't exist
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "🔐 Generating SSH key pair..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N ""
    echo "✅ SSH key created: $SSH_KEY_PATH"
else
    echo "✅ Using existing SSH key"
fi

# Configure SSH to use the key for GitHub
echo "⚙️  Configuring SSH for GitHub..."
mkdir -p "$HOME/.ssh"

# Check if GitHub config already exists
if grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    echo "⚠️  GitHub SSH config already exists in $SSH_CONFIG"
    read -p "Update configuration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove existing GitHub config block
        sed -i '/^Host github\.com$/,/^$/d' "$SSH_CONFIG"
        echo "🗑️  Removed existing GitHub configuration"
    else
        echo "ℹ️  Keeping existing SSH config"
    fi
fi

# Add GitHub SSH config if not present
if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_pi
    IdentitiesOnly yes

EOF
    echo "✅ SSH config updated"
fi

chmod 600 "$SSH_CONFIG"

# Display public key
echo ""
echo "📋 Your public SSH key:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$SSH_KEY_PATH.pub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Update Git remotes to use SSH (if in a git repo)
# Try to find git repo in _playground if not in current directory
GIT_REPO_DIR=""
if git rev-parse --git-dir &> /dev/null 2>&1; then
    GIT_REPO_DIR=$(pwd)
elif [ -d "$HOME/_playground/.git" ]; then
    GIT_REPO_DIR="$HOME/_playground"
    cd "$GIT_REPO_DIR"
else
    # No repo found - use _playground as default location
    GIT_REPO_DIR="$HOME/_playground"
fi

# Setup local repo if needed (when running setup command)
if [ "${SETUP_LOCAL_REPO:-false}" = "true" ] && [ ! -d "$GIT_REPO_DIR/.git" ]; then
    setup_local_repo
    echo ""
fi

if [ -d "$GIT_REPO_DIR/.git" ]; then
    cd "$GIT_REPO_DIR"
    CURRENT_DIR=$(pwd)
    echo "📂 Detected Git repository at: $CURRENT_DIR"
    
    # Fix non-standard remote name (Cursor expects 'origin')
    if git remote 2>/dev/null | grep -q "^main$" && ! git remote 2>/dev/null | grep -q "^origin$"; then
        echo "⚠️  Remote named 'main' detected (non-standard)"
        echo "🔧 Renaming remote 'main' → 'origin' (for Cursor compatibility)"
        git remote rename main origin
    fi
    
    # Get all remotes
    REMOTES=$(git remote 2>/dev/null)
    
    if [ -n "$REMOTES" ]; then
        # If SETUP_REMOTE is true, always call setup_remote (it will handle existing remotes)
        if [ "${SETUP_REMOTE:-false}" = "true" ]; then
            echo ""
            echo "📦 Setting up Git remote..."
            setup_remote
        else
            echo "🔄 Updating Git remotes to use SSH..."
            
            for REMOTE in $REMOTES; do
                URL=$(git remote get-url "$REMOTE" 2>/dev/null)
                
                # Convert HTTPS GitHub URLs to SSH
                if [[ "$URL" =~ https://github\.com/(.+)/(.+)(\.git)?$ ]]; then
                    USER="${BASH_REMATCH[1]}"
                    REPO="${BASH_REMATCH[2]%.git}"  # Remove .git if present
                    NEW_URL="git@github.com:$USER/$REPO.git"
                    
                    echo "  📝 $REMOTE: $URL → $NEW_URL"
                    git remote set-url "$REMOTE" "$NEW_URL"
                else
                    echo "  ℹ️  $REMOTE: $URL (not a GitHub HTTPS URL, skipping)"
                fi
            done
            
            echo "✅ Git remotes updated"
            echo ""
            git remote -v
            
            # Set origin/HEAD for Cursor compatibility
            if git remote 2>/dev/null | grep -q "^origin$"; then
                DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null | sed 's|^origin/||')
                if [ -z "$DEFAULT_BRANCH" ]; then
                    # Try to detect default branch
                    DEFAULT_BRANCH=$(git branch -r 2>/dev/null | grep "origin/HEAD" | sed 's|.*origin/||' || echo "main")
                    if [ "$DEFAULT_BRANCH" = "main" ] || [ "$DEFAULT_BRANCH" = "master" ]; then
                        echo "🔧 Setting origin/HEAD to origin/$DEFAULT_BRANCH"
                        git remote set-head origin "$DEFAULT_BRANCH" 2>/dev/null || git symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/main" 2>/dev/null || true
                    fi
                fi
            fi
        fi
    else
        # No remotes configured - set up new remote
        if [ "${SETUP_REMOTE:-false}" = "true" ]; then
            echo ""
            echo "📦 Setting up Git remote..."
            setup_remote
        else
            echo ""
            echo "📦 No remotes configured"
            read -p "Set up git remote? (Y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                setup_remote
            else
                echo "ℹ️  Skipping remote setup"
            fi
        fi
    fi
    
    # Fix SSH key permissions
    echo "🔒 Fixing SSH key permissions..."
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "$SSH_KEY_PATH.pub"
fi

# Configure Cursor git.path if workspace file exists
WORKSPACE_FILE="$HOME/.vscode/RPi-Full.code-workspace"
if [ -f "$WORKSPACE_FILE" ]; then
    echo "⚙️  Configuring Cursor git path..."
    if ! grep -q '"git.path"' "$WORKSPACE_FILE"; then
        # Add git.path to workspace settings
        sed -i '/"git.enabled":/i\    "git.path": "/usr/bin/git",' "$WORKSPACE_FILE"
        echo "✅ Added git.path to workspace settings"
    else
        echo "ℹ️  git.path already configured in workspace"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ GitHub SSH setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Next steps:"
echo "   1. Go to: https://github.com/settings/keys"
echo "   2. Click 'New SSH key'"
echo "   3. Title: 'Pi (github_pi)'"
echo "   4. Key type: 'Authentication Key'"
echo "   5. Paste the public key shown above"
echo "   6. Click 'Add SSH key'"
echo ""
echo "🧪 Test your connection:"
echo "   ssh -T git@github.com"
echo ""
echo "🚀 Push to GitHub:"
echo "   git push origin main"
echo ""
echo "⚠️  Cursor Setup:"
echo "   - Restart Cursor after running this script"
echo "   - Sign in to GitHub: Ctrl+Shift+P → 'GitHub: Sign In'"
echo "   - This enables Background Agents and git integration"
echo ""
echo "💡 Note: Git remotes should be named 'origin' (standard convention)"
echo "   If you have a remote named 'main', rename it:"
echo "   git remote rename main origin"
echo ""
echo "🔧 Management commands:"
echo "   $0 status         # Show current status"
echo "   $0 remove-key    # Remove SSH key"
echo "   $0 remove-remote # Remove/detach from git remote(s)"
echo "   $0 remove-repo    # Remove local git repository"
echo ""




