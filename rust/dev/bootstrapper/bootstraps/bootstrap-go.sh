#!/usr/bin/env bash
# Bootstrap Go installation - lightweight setup for building prompt tools
# Usage: bootstrap-go.sh [setup|remove] [options]

set -e

SCRIPT_NAME=$(basename "$0")
SHELL_RC_FILE=""

# Detect shell RC file
detect_shell_rc() {
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC_FILE="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC_FILE="$HOME/.bashrc"
    else
        SHELL_RC_FILE="$HOME/.profile"
    fi
}

# Show help
show_help() {
    cat << EOF
$SCRIPT_NAME - Bootstrap Go installation for prompt tools

Usage:
    $SCRIPT_NAME [command] [options]

Commands:
    setup       Install and configure Go
        Options:
            --package-manager    Install via system package manager (apt/yum/dnf/pacman/brew)
            --official           Download and install official Go binary
            --version VERSION    Install specific Go version (with --official)
            --gopath PATH        Set custom GOPATH (default: ~/go)
            --skip-path          Don't add Go to PATH in shell RC file
    
    remove      Uninstall Go
        Options:
            --package-manager    Remove via system package manager
            --official           Remove official Go installation
            --all                Remove both package manager and official installations
            --keep-path          Don't remove PATH entries from shell RC file
    
    status      Show current Go installation status
    help        Show this help message

Examples:
    $SCRIPT_NAME setup
    $SCRIPT_NAME setup --official --version 1.21.0
    $SCRIPT_NAME remove --package-manager
    $SCRIPT_NAME status

EOF
}

# Check if Go is installed
check_go_installed() {
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}')
        GO_BINARY=$(which go)
        echo "✅ Go is installed: $GO_VERSION"
        echo "   Binary: $GO_BINARY"
        
        # Check GOROOT
        if [ -n "$GOROOT" ]; then
            echo "   GOROOT: $GOROOT"
        else
            GOROOT=$(go env GOROOT 2>/dev/null || echo "")
            if [ -n "$GOROOT" ]; then
                echo "   GOROOT: $GOROOT"
            fi
        fi
        
        # Check GOPATH
        if [ -n "$GOPATH" ]; then
            echo "   GOPATH: $GOPATH"
        else
            GOPATH=$(go env GOPATH 2>/dev/null || echo "")
            if [ -n "$GOPATH" ]; then
                echo "   GOPATH: $GOPATH"
            fi
        fi
        
        return 0
    else
        echo "❌ Go is not installed or not in PATH"
        return 1
    fi
}

# Find Go installation locations
find_go_installations() {
    local locations=()
    
    # Check standard locations
    if [ -d "/usr/local/go" ]; then
        locations+=("/usr/local/go")
    fi
    if [ -d "$HOME/go" ]; then
        locations+=("$HOME/go")
    fi
    if [ -d "$HOME/.go" ]; then
        locations+=("$HOME/.go")
    fi
    
    # Check if golang package is installed
    if command -v dpkg &> /dev/null && dpkg -l | grep -q "^ii.*golang"; then
        locations+=("package-manager")
    fi
    
    echo "${locations[@]}"
}

# Setup Go via package manager
setup_package_manager() {
    echo "📦 Installing Go via package manager..."
    
    if command -v apt-get &> /dev/null; then
        echo "  Using apt-get..."
        sudo apt-get update
        sudo apt-get install -y golang-go
    elif command -v yum &> /dev/null; then
        echo "  Using yum..."
        sudo yum install -y golang
    elif command -v dnf &> /dev/null; then
        echo "  Using dnf..."
        sudo dnf install -y golang
    elif command -v pacman &> /dev/null; then
        echo "  Using pacman..."
        sudo pacman -S --noconfirm go
    elif command -v brew &> /dev/null; then
        echo "  Using brew..."
        brew install go
    else
        echo "❌ Error: Could not detect package manager"
        return 1
    fi
    
    # Verify installation
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}')
        echo "✅ Go installed successfully: $GO_VERSION"
        return 0
    else
        echo "❌ Go installation failed - binary not found in PATH"
        echo "   Try: export PATH=\$PATH:/usr/lib/go/bin"
        return 1
    fi
}

# Setup Go via official binary
setup_official() {
    local version="${1:-latest}"
    local install_dir="${2:-/usr/local/go}"
    
    echo "📥 Installing Go official binary..."
    
    if [ "$version" = "latest" ]; then
        # Get latest version
        VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
    else
        VERSION="go${version#go}"
    fi
    
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        armv7l|armv6l) ARCH="armv6l" ;;
        aarch64) ARCH="arm64" ;;
    esac
    
    TARBALL="${VERSION}.${OS}-${ARCH}.tar.gz"
    URL="https://go.dev/dl/${TARBALL}"
    
    echo "  Version: $VERSION"
    echo "  Architecture: $ARCH"
    echo "  OS: $OS"
    echo "  Install directory: $install_dir"
    
    # Download and install
    cd /tmp
    echo "  Downloading $TARBALL..."
    curl -L -o "$TARBALL" "$URL"
    
    echo "  Extracting..."
    sudo rm -rf "$install_dir"
    sudo tar -C /usr/local -xzf "$TARBALL"
    
    # Add to PATH
    if [ "$SKIP_PATH" != "true" ]; then
        add_go_to_path "$install_dir"
    fi
    
    # Verify
    export PATH="$install_dir/bin:$PATH"
    if "$install_dir/bin/go" version &>/dev/null; then
        GO_VERSION=$("$install_dir/bin/go" version | awk '{print $3}')
        echo "✅ Go installed successfully: $GO_VERSION"
        echo "   Add to PATH: export PATH=\$PATH:$install_dir/bin"
        return 0
    else
        echo "❌ Go installation verification failed"
        return 1
    fi
}

# Add Go to PATH in shell RC file
add_go_to_path() {
    local go_bin_dir="$1"
    detect_shell_rc
    
    if [ -z "$SHELL_RC_FILE" ]; then
        echo "⚠️  Could not detect shell RC file"
        return
    fi
    
    # Check if already added
    if grep -q "go/bin" "$SHELL_RC_FILE" 2>/dev/null; then
        echo "ℹ️  Go PATH entry already exists in $SHELL_RC_FILE"
        return
    fi
    
    echo "📝 Adding Go to PATH in $SHELL_RC_FILE..."
    cat >> "$SHELL_RC_FILE" << EOF

# Go environment (added by bootstrap-go.sh)
export PATH="\$PATH:$go_bin_dir"
export GOPATH="\${GOPATH:-\$HOME/go}"
export PATH="\$PATH:\$GOPATH/bin"
EOF
    
    echo "✅ Added Go to PATH"
    echo "   Run: source $SHELL_RC_FILE"
    echo "   Or restart your terminal"
}

# Remove Go via package manager
remove_package_manager() {
    echo "🗑️  Removing Go via package manager..."
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get remove -y golang-go golang-* 2>/dev/null || true
        sudo apt-get autoremove -y 2>/dev/null || true
    elif command -v yum &> /dev/null; then
        sudo yum remove -y golang 2>/dev/null || true
    elif command -v dnf &> /dev/null; then
        sudo dnf remove -y golang 2>/dev/null || true
    elif command -v pacman &> /dev/null; then
        sudo pacman -R --noconfirm go 2>/dev/null || true
    elif command -v brew &> /dev/null; then
        brew uninstall go 2>/dev/null || true
    fi
    
    echo "✅ Package manager Go removed"
}

# Remove official Go installation
remove_official() {
    echo "🗑️  Removing official Go installation..."
    
    if [ -d "/usr/local/go" ]; then
        sudo rm -rf /usr/local/go
        echo "✅ Removed /usr/local/go"
    fi
    
    if [ -d "$HOME/go" ] && [ -z "$(ls -A "$HOME/go" 2>/dev/null)" ]; then
        rm -rf "$HOME/go"
        echo "✅ Removed empty $HOME/go"
    fi
}

# Remove PATH entries
remove_path_entries() {
    detect_shell_rc
    
    if [ -z "$SHELL_RC_FILE" ] || [ ! -f "$SHELL_RC_FILE" ]; then
        return
    fi
    
    echo "🗑️  Removing Go PATH entries from $SHELL_RC_FILE..."
    
    # Remove Go-related lines
    sed -i '/# Go environment (added by bootstrap-go.sh)/,/^$/d' "$SHELL_RC_FILE" 2>/dev/null || true
    sed -i '/export PATH.*go\/bin/d' "$SHELL_RC_FILE" 2>/dev/null || true
    sed -i '/export GOPATH/d' "$SHELL_RC_FILE" 2>/dev/null || true
    
    echo "✅ Removed Go PATH entries"
    echo "   Run: source $SHELL_RC_FILE"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    shift || true
    
    # Parse flags
    local USE_PACKAGE_MANAGER=false
    local USE_OFFICIAL=false
    local VERSION="latest"
    local GOPATH_CUSTOM=""
    local SKIP_PATH=false
    local KEEP_PATH=false
    local REMOVE_ALL=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --package-manager)
                USE_PACKAGE_MANAGER=true
                shift
                ;;
            --official)
                USE_OFFICIAL=true
                shift
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --gopath)
                GOPATH_CUSTOM="$2"
                shift 2
                ;;
            --skip-path)
                SKIP_PATH=true
                shift
                ;;
            --keep-path)
                KEEP_PATH=true
                shift
                ;;
            --all)
                REMOVE_ALL=true
                shift
                ;;
            *)
                echo "❌ Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    case "$command" in
        setup)
            if [ "$USE_PACKAGE_MANAGER" = "true" ]; then
                setup_package_manager
            elif [ "$USE_OFFICIAL" = "true" ]; then
                setup_official "$VERSION"
            else
                # Default: try package manager first, fallback to official
                if ! setup_package_manager 2>/dev/null; then
                    echo "⚠️  Package manager installation failed, trying official binary..."
                    setup_official "$VERSION"
                fi
            fi
            
            # Set up GOPATH
            if [ -n "$GOPATH_CUSTOM" ]; then
                export GOPATH="$GOPATH_CUSTOM"
            fi
            
            # Add to PATH if not skipped
            if [ "$SKIP_PATH" != "true" ]; then
                if command -v go &> /dev/null; then
                    GO_BIN=$(dirname "$(which go)")
                    add_go_to_path "$GO_BIN"
                elif [ -d "/usr/local/go/bin" ]; then
                    add_go_to_path "/usr/local/go/bin"
                fi
            fi
            ;;
            
        remove)
            if [ "$REMOVE_ALL" = "true" ]; then
                remove_package_manager
                remove_official
            elif [ "$USE_PACKAGE_MANAGER" = "true" ]; then
                remove_package_manager
            elif [ "$USE_OFFICIAL" = "true" ]; then
                remove_official
            else
                # Default: remove both
                remove_package_manager
                remove_official
            fi
            
            if [ "$KEEP_PATH" != "true" ]; then
                remove_path_entries
            fi
            ;;
            
        status)
            check_go_installed
            echo ""
            echo "Installation locations:"
            find_go_installations | tr ' ' '\n' | sed 's/^/  - /'
            ;;
            
        help|--help|-h|"")
            show_help
            ;;
            
        *)
            echo "❌ Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
