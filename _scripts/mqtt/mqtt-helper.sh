#!/usr/bin/env bash
# MQTT Helper - Orchestrator script for MQTT broker management
# Provides a unified interface for all MQTT operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSWD_FILE="/etc/mosquitto/passwd"
CONF_FILE="/etc/mosquitto/mosquitto.conf"
SECRETS_FILE="${HOME}/.secrets"

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
    echo "  echo 'MQTT_PASSWORD=your_password' >> ~/.secrets"
    echo "  chmod 600 ~/.secrets"
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
    
    # Check if anonymous access is enabled
    local anonymous_enabled=false
    if [ -f "$CONF_FILE" ]; then
        if grep -q "^allow_anonymous.*true" "$CONF_FILE"; then
            anonymous_enabled=true
        fi
    fi
    
    # Get credentials if not provided and anonymous access is disabled
    if [ -z "$username" ] && [ "$anonymous_enabled" = "false" ]; then
        if [ -f "$PASSWD_FILE" ] && [ -s "$PASSWD_FILE" ]; then
            username=$(cut -d: -f1 "$PASSWD_FILE" | head -1)
            password=$(get_password_from_secrets || echo "")
            
            if [ -z "$password" ]; then
                error "Authentication required but password not found"
                info "Please provide credentials:"
                echo "  Option 1: Create secrets file:"
                echo "    echo 'MQTT_PASSWORD=your_password' >> ~/.secrets"
                echo "    chmod 600 ~/.secrets"
                echo ""
                echo "  Option 2: Use monitor with credentials:"
                echo "    mqtt monitor \"$topic\" $host <username> <password>"
                exit 1
            fi
        fi
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

# List all broker items (clients, topics, retained messages)
list_broker() {
    local host="${1:-localhost}"
    local username="${2:-}"
    local password="${3:-}"
    
    # Get credentials if not provided
    if [ -z "$username" ] && [ -f "$PASSWD_FILE" ] && [ -s "$PASSWD_FILE" ]; then
        username=$(cut -d: -f1 "$PASSWD_FILE" | head -1)
        password=$(get_password_from_secrets || echo "")
    fi
    
    info "MQTT Broker Contents"
    echo ""
    
    # Connected Clients
    echo -e "${BLUE}📡 Connected Clients (recent):${NC}"
    if systemctl is-active --quiet mosquitto; then
        # Extract client info from recent logs - look for "as clientname"
        local clients=$(journalctl -u mosquitto --since "10 minutes ago" --no-pager 2>&1 | \
            grep -E "New client connected" | \
            sed -E 's/.*as ([^ ]+).*/\1/' | \
            sort -u)
        
        if [ -n "$clients" ]; then
            echo "$clients" | while read -r client; do
                # Check if client is still active (has recent activity)
                local last_activity=$(journalctl -u mosquitto --since "2 minutes ago" --no-pager 2>&1 | \
                    grep -c "$client" || echo "0")
                if [ "$last_activity" -gt 0 ]; then
                    echo "  • $client (active)"
                else
                    echo "  • $client (recent)"
                fi
            done
        else
            echo "  (No clients found in recent logs)"
        fi
    else
        warning "Mosquitto service is not running"
    fi
    
    echo ""
    
    # Recent Topics
    echo -e "${BLUE}📋 Recent Topics (last 10 minutes):${NC}"
    if systemctl is-active --quiet mosquitto; then
        local topics=$(journalctl -u mosquitto --since "10 minutes ago" --no-pager 2>&1 | \
            grep -E "Received PUBLISH" | \
            sed -E "s/.*'([^']+)'.*/\1/" | \
            sort -u)
        
        if [ -n "$topics" ]; then
            echo "$topics" | while read -r topic; do
                # Count messages for this topic
                local count=$(journalctl -u mosquitto --since "10 minutes ago" --no-pager 2>&1 | \
                    grep -c "Received PUBLISH.*'${topic}'" || echo "0")
                echo "  • $topic (${count} messages)"
            done
        else
            echo "  (No topics found in recent logs)"
        fi
    else
        warning "Mosquitto service is not running"
    fi
    
    echo ""
    
    # Retained Messages
    echo -e "${BLUE}💾 Retained Messages:${NC}"
    local retained_output=""
    local retained_error=""
    
    if [ -n "$username" ] && [ -n "$password" ]; then
        # Try to get retained messages by subscribing briefly
        retained_output=$(timeout 3 mosquitto_sub -h "$host" -u "$username" -P "$password" -t "#" --retained-only -C 100 -W 2 2>&1)
        retained_error=$(echo "$retained_output" | grep -i "error\|refused\|unauthorized" || echo "")
    elif [ -n "$username" ]; then
        retained_output=$(timeout 3 mosquitto_sub -h "$host" -u "$username" -t "#" --retained-only -C 100 -W 2 2>&1)
        retained_error=$(echo "$retained_output" | grep -i "error\|refused\|unauthorized" || echo "")
    else
        retained_output=$(timeout 3 mosquitto_sub -h "$host" -t "#" --retained-only -C 100 -W 2 2>&1)
        retained_error=$(echo "$retained_output" | grep -i "error\|refused\|unauthorized" || echo "")
    fi
    
    if [ -n "$retained_error" ]; then
        echo "  (Authentication required or no retained messages)"
    elif [ -n "$retained_output" ]; then
        # Filter out connection messages and show only topic:payload
        echo "$retained_output" | grep -v -E "Client|CONNECT|SUBSCRIBE|SUBACK|DISCONNECT" | \
            grep -v "^$" | head -20 | while IFS= read -r line; do
            if [ -n "$line" ]; then
                echo "  • $line"
            fi
        done
        local retained_count=$(echo "$retained_output" | grep -v -E "Client|CONNECT|SUBSCRIBE|SUBACK|DISCONNECT" | grep -v "^$" | wc -l)
        if [ "$retained_count" -gt 20 ]; then
            echo "  ... and $((retained_count - 20)) more"
        fi
    else
        echo "  (No retained messages found)"
    fi
    
    echo ""
    
    # Recent Activity Summary
    echo -e "${BLUE}📊 Recent Activity Summary:${NC}"
    if systemctl is-active --quiet mosquitto; then
        local recent_pub=$(journalctl -u mosquitto --since "10 minutes ago" --no-pager 2>&1 | grep -c "Received PUBLISH" || echo "0")
        local recent_conn=$(journalctl -u mosquitto --since "10 minutes ago" --no-pager 2>&1 | grep -c "New client connected" || echo "0")
        local recent_sub=$(journalctl -u mosquitto --since "10 minutes ago" --no-pager 2>&1 | grep -c "Received SUBSCRIBE" || echo "0")
        
        echo "  • Published messages: $recent_pub"
        echo "  • New connections: $recent_conn"
        echo "  • Subscriptions: $recent_sub"
    else
        warning "Mosquitto service is not running"
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
  list [host]              List all broker items (clients, topics, retained messages)
  test [host] [port]       Test connection to broker
  monitor [topic] [host]   Monitor MQTT topics (default: #, localhost)
  help                     Show this help message

Examples:
  $0 setup-universal
  $0 user add esp32 mypassword
  $0 user list
  $0 status
  $0 list                    # Show all broker contents
  $0 list 192.168.1.50       # Show contents from remote broker
  $0 test localhost 1883
  $0 monitor "sensors/#" 192.168.1.50

Environment Variables:
  MQTT_USERNAME            Default username (default: mqtt)
  MQTT_PASSWORD            Password (or use ~/.secrets file)

Secrets File:
  Store password in ~/.secrets:
    echo 'MQTT_PASSWORD=your_password' >> ~/.secrets
    chmod 600 ~/.secrets
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
        list)
            list_broker "${2:-localhost}" "$3" "$4"
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


