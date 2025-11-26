#!/usr/bin/env bash
# MQTT Helper - Orchestrator script for MQTT broker management
# Provides a unified interface for all MQTT operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSWD_FILE="/etc/mosquitto/passwd"
CONF_FILE="/etc/mosquitto/mosquitto.conf"
SECRETS_FILE="${HOME}/.mqtt_secrets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This command requires root privileges. Use sudo."
        exit 1
    fi
}

# Get password from secrets file or environment
get_password_from_secrets() {
    if [ -f "$SECRETS_FILE" ]; then
        if grep -q "^MQTT_PASSWORD=" "$SECRETS_FILE" 2>/dev/null; then
            grep "^MQTT_PASSWORD=" "$SECRETS_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'"
            return 0
        elif [ -s "$SECRETS_FILE" ]; then
            head -n1 "$SECRETS_FILE" | tr -d '\n'
            return 0
        fi
    fi
    
    if [ -n "$MQTT_PASSWORD" ]; then
        echo "$MQTT_PASSWORD"
        return 0
    fi
    
    return 1
}

# Setup universal authentication
setup_universal_auth() {
    check_root
    
    info "Setting up universal MQTT authentication..."
    
    # Get password
    PASSWORD=$(get_password_from_secrets)
    if [ -z "$PASSWORD" ]; then
        read -sp "Enter MQTT password: " PASSWORD
        echo
        read -sp "Confirm password: " PASSWORD_CONFIRM
        echo
        
        if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
            error "Passwords don't match"
            exit 1
        fi
    fi
    
    USERNAME="${MQTT_USERNAME:-mqtt}"
    
    # Use the add-mqtt-user script
    "$SCRIPT_DIR/add-mqtt-user.sh" "$USERNAME" "$PASSWORD" > /dev/null 2>&1
    
    # Disable anonymous access
    if [ -f "$CONF_FILE" ]; then
        if grep -q "^allow_anonymous" "$CONF_FILE"; then
            sed -i 's/^allow_anonymous.*/allow_anonymous false/' "$CONF_FILE"
        else
            if grep -q "^listener" "$CONF_FILE"; then
                sed -i '/^listener/i allow_anonymous false' "$CONF_FILE"
            else
                echo "allow_anonymous false" >> "$CONF_FILE"
            fi
        fi
    fi
    
    # Restart service
    systemctl restart mosquitto > /dev/null 2>&1
    
    success "Universal authentication setup complete!"
    info "Username: $USERNAME"
    info "Password stored in: $SECRETS_FILE (if used)"
    echo ""
    info "To store password in secrets file:"
    echo "  echo 'MQTT_PASSWORD=your_password' > ~/.mqtt_secrets"
    echo "  chmod 600 ~/.mqtt_secrets"
}

# Add a user
add_user() {
    check_root
    
    if [ -z "$1" ]; then
        error "Usage: $0 user add <username> [password]"
        exit 1
    fi
    
    USERNAME="$1"
    PASSWORD="$2"
    
    "$SCRIPT_DIR/add-mqtt-user.sh" "$USERNAME" "$PASSWORD"
}

# List all users
list_users() {
    if [ ! -f "$PASSWD_FILE" ]; then
        warning "Password file not found. No users configured."
        return
    fi
    
    if [ ! -s "$PASSWD_FILE" ]; then
        warning "Password file is empty. No users configured."
        return
    fi
    
    info "MQTT Users:"
    cut -d: -f1 "$PASSWD_FILE" | while read -r user; do
        echo "  • $user"
    done
}

# Remove a user
remove_user() {
    check_root
    
    if [ -z "$1" ]; then
        error "Usage: $0 user remove <username>"
        exit 1
    fi
    
    USERNAME="$1"
    
    if [ ! -f "$PASSWD_FILE" ]; then
        error "Password file not found"
        exit 1
    fi
    
    if ! grep -q "^${USERNAME}:" "$PASSWD_FILE" 2>/dev/null; then
        error "User '$USERNAME' not found"
        exit 1
    fi
    
    # Remove user from password file
    sed -i "/^${USERNAME}:/d" "$PASSWD_FILE"
    
    # Restart service
    systemctl restart mosquitto > /dev/null 2>&1
    
    success "User '$USERNAME' removed"
}

# Show status
show_status() {
    info "MQTT Broker Status:"
    echo ""
    
    # Service status
    if systemctl is-active --quiet mosquitto; then
        success "Service: Running"
    else
        error "Service: Not running"
    fi
    
    # Port check
    if netstat -tlnp 2>/dev/null | grep -q ":1883 " || ss -tlnp 2>/dev/null | grep -q ":1883 "; then
        success "Port 1883: Listening"
    else
        warning "Port 1883: Not listening"
    fi
    
    # Anonymous access
    if [ -f "$CONF_FILE" ]; then
        if grep -q "^allow_anonymous.*true" "$CONF_FILE"; then
            warning "Anonymous access: ENABLED (insecure!)"
        else
            success "Anonymous access: DISABLED"
        fi
    fi
    
    # Users
    echo ""
    list_users
    
    # Broker info
    echo ""
    if command -v mosquitto &> /dev/null; then
        info "Broker version:"
        mosquitto -v 2>&1 | head -1 | sed 's/^/  /'
    fi
}

# Test connection
test_connection() {
    local host="${1:-localhost}"
    local port="${2:-1883}"
    local username="${3:-}"
    local password="${4:-}"
    
    info "Testing MQTT connection to $host:$port..."
    
    # Try to get credentials
    if [ -z "$username" ]; then
        if [ -f "$PASSWD_FILE" ] && [ -s "$PASSWD_FILE" ]; then
            username=$(cut -d: -f1 "$PASSWD_FILE" | head -1)
            password=$(get_password_from_secrets || echo "")
        fi
    fi
    
    if [ -z "$username" ]; then
        error "No username provided and no users found"
        return 1
    fi
    
    # Test publish
    if [ -n "$password" ]; then
        if mosquitto_pub -h "$host" -p "$port" -u "$username" -P "$password" -t "test/connection" -m "test" -W 2 > /dev/null 2>&1; then
            success "Connection successful!"
            info "  Host: $host:$port"
            info "  Username: $username"
            return 0
        else
            error "Connection failed"
            return 1
        fi
    else
        if mosquitto_pub -h "$host" -p "$port" -t "test/connection" -m "test" -W 2 > /dev/null 2>&1; then
            success "Connection successful (anonymous)"
            return 0
        else
            error "Connection failed"
            return 1
        fi
    fi
}

# Monitor topics
monitor() {
    local topic="${1:-#}"
    local host="${2:-localhost}"
    local username="${3:-}"
    local password="${4:-}"
    
    # Get credentials if not provided
    if [ -z "$username" ] && [ -f "$PASSWD_FILE" ] && [ -s "$PASSWD_FILE" ]; then
        username=$(cut -d: -f1 "$PASSWD_FILE" | head -1)
        password=$(get_password_from_secrets || echo "")
    fi
    
    info "Monitoring topic: $topic"
    info "Press Ctrl+C to stop"
    echo ""
    
    if [ -n "$username" ] && [ -n "$password" ]; then
        mosquitto_sub -h "$host" -u "$username" -P "$password" -t "$topic" -v
    elif [ -n "$username" ]; then
        mosquitto_sub -h "$host" -u "$username" -t "$topic" -v
    else
        mosquitto_sub -h "$host" -t "$topic" -v
    fi
}

# Show usage
show_usage() {
    cat << EOF
MQTT Helper - Unified MQTT broker management tool

Usage: $0 <command> [options]

Commands:
  setup-universal          Set up universal authentication (one password for all)
  user add <name> [pass]   Add a new user (password optional, will prompt)
  user list                List all users
  user remove <name>       Remove a user
  status                   Show broker status
  test [host] [port]       Test connection to broker
  monitor [topic] [host]   Monitor MQTT topics (default: #, localhost)
  help                     Show this help message

Examples:
  $0 setup-universal
  $0 user add esp32 mypassword
  $0 user list
  $0 status
  $0 test localhost 1883
  $0 monitor "sensors/#" 192.168.1.50

Environment Variables:
  MQTT_USERNAME            Default username (default: mqtt)
  MQTT_PASSWORD            Password (or use ~/.mqtt_secrets file)

Secrets File:
  Store password in ~/.mqtt_secrets:
    echo 'MQTT_PASSWORD=your_password' > ~/.mqtt_secrets
    chmod 600 ~/.mqtt_secrets
EOF
}

# Main command dispatcher
main() {
    case "${1:-help}" in
        setup-universal)
            setup_universal_auth
            ;;
        user)
            case "${2:-}" in
                add)
                    add_user "$3" "$4"
                    ;;
                list)
                    list_users
                    ;;
                remove)
                    remove_user "$3"
                    ;;
                *)
                    error "Unknown user command: ${2:-}"
                    echo "  Use: add, list, or remove"
                    exit 1
                    ;;
            esac
            ;;
        status)
            show_status
            ;;
        test)
            test_connection "$2" "$3" "$4" "$5"
            ;;
        monitor)
            monitor "${2:-#}" "${3:-localhost}" "$4" "$5"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            error "Unknown command: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"




