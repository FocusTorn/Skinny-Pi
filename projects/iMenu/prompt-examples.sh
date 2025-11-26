#!/usr/bin/env bash
# Examples of using interactive prompts from bash scripts

# ============================================================================
# OPTION 1: Using huh? (Charmbracelet) - RECOMMENDED: Standalone prompt library
# ============================================================================

# First, compile the Go program:
# cd /root/_playground/projects/iMenu
# go mod tidy  # Downloads dependencies
# go build -o prompt-huh prompt-huh.go

# Then use it in bash:
use_huh() {
    local PROMPT_BIN="$HOME/_playground/projects/iMenu/prompt-huh"
    
    # Text input
    NAME=$("$PROMPT_BIN" input "What is your name?")
    echo "Hello, $NAME!"
    
    # Text input with default value
    REPO=$("$PROMPT_BIN" input "Repository name:" "my-repo")
    echo "Repository: $REPO"
    
    # Select from options
    COLOR=$("$PROMPT_BIN" select "Choose a color:" "Red" "Blue" "Green" "Yellow")
    echo "You chose: $COLOR"
    
    # Confirmation
    if "$PROMPT_BIN" confirm "Do you want to continue?"; then
        echo "User confirmed"
    else
        echo "User cancelled"
    fi
    
    # Multi-select
    SELECTED=$("$PROMPT_BIN" multiselect "Choose multiple colors:" "Red" "Blue" "Green" "Yellow")
    echo "You selected:"
    echo "$SELECTED" | while read -r item; do
        echo "  - $item"
    done
}

# ============================================================================
# OPTION 2: Using bubbletea (Go wrapper) - Full TUI framework
# ============================================================================

# First, compile the Go program:
# cd /root/_playground/projects/iMenu
# go mod tidy  # Downloads dependencies
# go build -o prompt-bubbletea prompt-bubbletea.go

# Then use it in bash:
use_bubbletea() {
    local PROMPT_BIN="$HOME/_playground/projects/iMenu/prompt-bubbletea"
    
    # Text input
    NAME=$("$PROMPT_BIN" input "What is your name?")
    echo "Hello, $NAME!"
    
    # Text input with default value
    REPO=$("$PROMPT_BIN" input "Repository name:" "my-repo")
    echo "Repository: $REPO"
    
    # Select from options
    COLOR=$("$PROMPT_BIN" select "Choose a color:" "Red" "Blue" "Green" "Yellow")
    echo "You chose: $COLOR"
    
    # Confirmation
    if "$PROMPT_BIN" confirm "Do you want to continue?"; then
        echo "User confirmed"
    else
        echo "User cancelled"
    fi
}

# ============================================================================
# OPTION 3: Using survey (Go wrapper) - Archived, use huh? instead
# ============================================================================

# First, compile the Go program:
# cd /root/_playground/projects/iMenu
# go mod init prompt-survey  # if not already done
# go get github.com/AlecAivazis/survey/v2
# go build -o prompt-survey prompt-survey.go

# Then use it in bash:
use_survey() {
    local PROMPT_BIN="$HOME/_playground/projects/iMenu/prompt-survey"
    
    # Text input
    NAME=$(./prompt-survey input "What is your name?")
    echo "Hello, $NAME!"
    
    # Select from options
    COLOR=$(./prompt-survey select "Choose a color:" "Red" "Blue" "Green" "Yellow")
    echo "You chose: $COLOR"
    
    # Confirmation
    if ./prompt-survey confirm "Do you want to continue?"; then
        echo "User confirmed"
    else
        echo "User cancelled"
    fi
    
    # Password input
    PASSWORD=$(./prompt-survey password "Enter password:")
    echo "Password entered (length: ${#PASSWORD})"
}

# ============================================================================
# OPTION 4: Using whiptail (built-in on most Linux systems)
# ============================================================================

use_whiptail() {
    # Text input
    NAME=$(whiptail --inputbox "What is your name?" 8 40 --title "Input" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
        echo "Hello, $NAME!"
    fi
    
    # Select from menu
    COLOR=$(whiptail --menu "Choose a color:" 15 40 4 \
        "1" "Red" \
        "2" "Blue" \
        "3" "Green" \
        "4" "Yellow" \
        3>&1 1>&2 2>&3)
    echo "You chose option: $COLOR"
    
    # Confirmation (yes/no)
    if whiptail --yesno "Do you want to continue?" 8 40; then
        echo "User confirmed"
    else
        echo "User cancelled"
    fi
    
    # Checkbox (multiple selections)
    whiptail --checklist "Select options:" 15 40 4 \
        "Option1" "First option" OFF \
        "Option2" "Second option" ON \
        "Option3" "Third option" OFF \
        "Option4" "Fourth option" ON \
        3>&1 1>&2 2>&3
}

# ============================================================================
# OPTION 5: Using dialog (similar to whiptail, more features)
# ============================================================================

use_dialog() {
    # Text input
    NAME=$(dialog --inputbox "What is your name?" 8 40 --stdout)
    if [ $? -eq 0 ]; then
        echo "Hello, $NAME!"
    fi
    
    # Select from menu
    COLOR=$(dialog --menu "Choose a color:" 15 40 4 \
        "1" "Red" \
        "2" "Blue" \
        "3" "Green" \
        "4" "Yellow" \
        --stdout)
    echo "You chose: $COLOR"
    
    # Confirmation
    if dialog --yesno "Do you want to continue?" 8 40; then
        echo "User confirmed"
    else
        echo "User cancelled"
    fi
}

# ============================================================================
# OPTION 6: Using fzf (fuzzy finder - excellent for selections)
# ============================================================================

use_fzf() {
    # Select from list (single)
    COLOR=$(echo -e "Red\nBlue\nGreen\nYellow" | fzf --prompt "Choose color: " --height 40%)
    echo "You chose: $COLOR"
    
    # Multi-select
    SELECTED=$(echo -e "Option1\nOption2\nOption3\nOption4" | fzf --multi --prompt "Select options: " --height 40%)
    echo "Selected: $SELECTED"
    
    # With preview
    FILE=$(find . -type f | fzf --preview "cat {}" --height 40%)
    echo "Selected file: $FILE"
}

# ============================================================================
# OPTION 7: Using bash built-in select (simple, no dependencies)
# ============================================================================

use_bash_select() {
    # Simple menu
    echo "Choose a color:"
    select COLOR in "Red" "Blue" "Green" "Yellow" "Quit"; do
        case $COLOR in
            Quit)
                echo "Exiting..."
                break
                ;;
            *)
                echo "You chose: $COLOR"
                break
                ;;
        esac
    done
    
    # Text input (basic)
    read -p "Enter your name: " NAME
    echo "Hello, $NAME!"
    
    # Confirmation
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "User confirmed"
    else
        echo "User cancelled"
    fi
}

# ============================================================================
# RECOMMENDED: Helper functions for common use cases
# ============================================================================

# Prompt for text input
prompt_input() {
    local message="${1:-Enter value:}"
    local default="${2:-}"
    
    if command -v whiptail &> /dev/null; then
        local result
        result=$(whiptail --inputbox "$message" 8 40 "$default" 3>&1 1>&2 2>&3)
        [ $? -eq 0 ] && echo "$result" || echo "$default"
    elif command -v dialog &> /dev/null; then
        dialog --inputbox "$message" 8 40 "$default" --stdout 2>/dev/null || echo "$default"
    else
        read -p "$message " result
        echo "${result:-$default}"
    fi
}

# Prompt for selection
prompt_select() {
    local message="${1:-Select option:}"
    shift
    local options=("$@")
    
    if command -v whiptail &> /dev/null; then
        local menu_args=()
        local i=1
        for opt in "${options[@]}"; do
            menu_args+=("$i" "$opt")
            ((i++))
        done
        local choice
        choice=$(whiptail --menu "$message" 15 40 "${#options[@]}" "${menu_args[@]}" 3>&1 1>&2 2>&3)
        [ -n "$choice" ] && echo "${options[$((choice-1))]}"
    elif command -v fzf &> /dev/null; then
        printf '%s\n' "${options[@]}" | fzf --prompt "$message " --height 40%
    else
        echo "Select an option:" >&2
        select opt in "${options[@]}"; do
            [ -n "$opt" ] && echo "$opt" && break
        done
    fi
}

# Prompt for confirmation
prompt_confirm() {
    local message="${1:-Continue?}"
    
    if command -v whiptail &> /dev/null; then
        whiptail --yesno "$message" 8 40
    elif command -v dialog &> /dev/null; then
        dialog --yesno "$message" 8 40
    else
        read -p "$message (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Example usage of helper functions
example_usage() {
    # Get user input
    NAME=$(prompt_input "What is your name?")
    echo "Hello, $NAME!"
    
    # Select from options
    COLOR=$(prompt_select "Choose a color:" "Red" "Blue" "Green" "Yellow")
    echo "You chose: $COLOR"
    
    # Confirm action
    if prompt_confirm "Do you want to proceed?"; then
        echo "Proceeding..."
    else
        echo "Cancelled."
    fi
}

# Run example if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    example_usage
fi

