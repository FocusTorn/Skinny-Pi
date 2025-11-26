#!/usr/bin/env bash
# Setup Git remote for Skinny-Pi repository
# Usage: setup-git-remote.sh [github-username] [repo-name]

set -e

REPO_DIR="/root/_playground"
GITHUB_USER="${1:-}"
REPO_NAME="${2:-Skinny-Pi}"

if [ -z "$GITHUB_USER" ]; then
    echo "Usage: $0 <github-username> [repo-name]"
    echo "   Example: $0 myusername Skinny-Pi"
    exit 1
fi

cd "$REPO_DIR"

# Check if remote already exists
if git remote | grep -q "^origin$"; then
    CURRENT_URL=$(git remote get-url origin)
    echo "⚠️  Remote 'origin' already exists: $CURRENT_URL"
    read -p "Update to git@github.com:$GITHUB_USER/$REPO_NAME.git? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        exit 0
    fi
    git remote set-url origin "git@github.com:$GITHUB_USER/$REPO_NAME.git"
    echo "✅ Updated remote 'origin'"
else
    git remote add origin "git@github.com:$GITHUB_USER/$REPO_NAME.git"
    echo "✅ Added remote 'origin'"
fi

# Verify remote
echo ""
echo "📋 Current remotes:"
git remote -v

# Set upstream branch
echo ""
echo "🔧 Setting upstream branch..."
git branch --set-upstream-to=origin/main main 2>/dev/null || echo "⚠️  Upstream will be set on first push"

echo ""
echo "✅ Git remote configured!"
echo ""
echo "📝 Next steps:"
echo "   1. Create the repository on GitHub: https://github.com/new"
echo "      Name: $REPO_NAME"
echo "      Don't initialize with README (we already have one)"
echo ""
echo "   2. Push to GitHub:"
echo "      git add ."
echo "      git commit -m 'Initial Skinny-Pi repository setup'"
echo "      git push -u origin main"
echo ""



