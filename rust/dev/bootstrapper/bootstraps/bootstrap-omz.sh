#!/usr/bin/env bash
# Bootstrap Oh-My-Zsh installation for system restore
# This script installs OMZ from scratch and symlinks custom configs from _playground

set -e

CUSTOM_DIR="$HOME/_playground/zsh/custom"

echo "🚀 Bootstrapping Oh-My-Zsh installation..."

# Check if zsh is installed, install if missing
if ! command -v zsh &> /dev/null; then
    echo "📦 zsh not found. Installing zsh..."
    
    # Detect package manager and install zsh
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y zsh
    elif command -v yum &> /dev/null; then
        sudo yum install -y zsh
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y zsh
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm zsh
    elif command -v brew &> /dev/null; then
        brew install zsh
    else
        echo "❌ Error: Could not detect package manager to install zsh"
        echo "   Please install zsh manually and run this script again"
        exit 1
    fi
    
    echo "✅ zsh installed successfully"
else
    echo "✅ zsh is already installed ($(zsh --version))"
fi

# Verify custom directory exists (should be in repo)
if [ ! -d "$CUSTOM_DIR" ]; then
    echo "❌ Error: Custom directory not found at $CUSTOM_DIR"
    echo "   Make sure you've cloned the restore repo properly!"
    exit 1
fi

# Check if OMZ is already installed
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "⚠️  Oh-My-Zsh already exists at ~/.oh-my-zsh"
    read -p "Remove and reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing existing installation..."
        rm -rf "$HOME/.oh-my-zsh"
    else
        echo "❌ Installation cancelled"
        exit 0
    fi
fi

# Install Oh-My-Zsh
echo "📥 Installing Oh-My-Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Remove the default custom directory and replace with symlink
echo "🔗 Setting up custom directory symlink..."
rm -rf "$HOME/.oh-my-zsh/custom"
ln -s "$CUSTOM_DIR" "$HOME/.oh-my-zsh/custom"

# Populate plugins if directories exist but are empty (as per Oh My Zsh installation)
echo "🔌 Checking zsh plugins..."
PLUGINS_DIR="$CUSTOM_DIR/plugins"

# Helper function to populate plugin if empty
populate_plugin() {
    local plugin_name=$1
    local plugin_repo=$2
    local plugin_file=$3
    local plugin_path="$PLUGINS_DIR/$plugin_name"
    
    if [ ! -d "$plugin_path" ]; then
        echo "  📦 Installing $plugin_name (directory missing)..."
        git clone --depth=1 "$plugin_repo" "$plugin_path"
    elif [ -z "$(ls -A "$plugin_path" 2>/dev/null)" ] || [ ! -f "$plugin_path/$plugin_file" ]; then
        echo "  📦 Populating $plugin_name (directory exists but is empty)..."
        rm -rf "$plugin_path"
        git clone --depth=1 "$plugin_repo" "$plugin_path"
    else
        echo "  ✅ $plugin_name already installed"
    fi
}

# Populate plugins (only if empty, per Oh My Zsh standard installation)
populate_plugin "zsh-autosuggestions" \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "zsh-autosuggestions.zsh"

populate_plugin "zsh-syntax-highlighting" \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "zsh-syntax-highlighting.zsh"

# Configure git to ignore the symlinked custom directory
echo "⚙️  Configuring git to ignore custom directory..."
echo "custom/" >> "$HOME/.oh-my-zsh/.git/info/exclude"

# Set up symlinks for zsh dot files
echo "🔗 Setting up zsh dot file symlinks..."
ZSH_DIR="$HOME/_playground/zsh"

for dotfile in .zshrc .zshenv .zprofile; do
    if [ -f "$ZSH_DIR/$dotfile" ]; then
        # Backup existing file if it exists and is not a symlink
        if [ -f "$HOME/$dotfile" ] && [ ! -L "$HOME/$dotfile" ]; then
            echo "  💾 Backing up existing $dotfile to ${dotfile}.bak"
            mv "$HOME/$dotfile" "$HOME/${dotfile}.bak"
        fi
        # Remove existing file/symlink if it exists
        if [ -f "$HOME/$dotfile" ] || [ -L "$HOME/$dotfile" ]; then
            rm -f "$HOME/$dotfile"
        fi
        # Create symlink
        ln -s "$ZSH_DIR/$dotfile" "$HOME/$dotfile"
        echo "  ✅ Linked $HOME/$dotfile -> $ZSH_DIR/$dotfile"
    else
        echo "  ⚠️  Warning: $ZSH_DIR/$dotfile not found, skipping..."
    fi
done

# Remove contributor cruft to keep it clean
echo "🧹 Cleaning up unnecessary files..."
rm -rf "$HOME/.oh-my-zsh/.github"
rm -f "$HOME/.oh-my-zsh/"{CODE_OF_CONDUCT,CONTRIBUTING,SECURITY}.md
rm -f "$HOME/.oh-my-zsh/README.md"

# Verify setup
echo ""
echo "✅ Oh-My-Zsh installation complete!"
echo "📁 Custom directory: $CUSTOM_DIR"
echo "🔗 Symlink: ~/.oh-my-zsh/custom -> $CUSTOM_DIR"
ls -la "$HOME/.oh-my-zsh/custom"
echo ""
echo "📄 Zsh dot files symlinked:"
for dotfile in .zshrc .zshenv .zprofile; do
    if [ -L "$HOME/$dotfile" ]; then
        echo "   $HOME/$dotfile -> $(readlink "$HOME/$dotfile")"
    fi
done
echo ""
echo "📝 Note: OMZ updates will work normally (git ignores symlinked custom/)"
echo "   To update: omz update"

