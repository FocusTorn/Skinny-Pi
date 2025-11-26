#!/usr/bin/env bash
# Universal prompt helper - uses best available tool (whiptail > dialog > fzf > bash)
# Usage: source this file or call functions directly

# Detect available prompt tool
_detect_prompt_tool() {
    if command -v whiptail &> /dev/null; then
        echo "whiptail"
    elif command -v dialog &> /dev/null; then
        echo "dialog"
    elif command -v fzf &> /dev/null; then
        echo "fzf"
    else
        echo "bash"
    fi
}

_PROMPT_TOOL=$(_detect_prompt_tool)

# Prompt for text input
prompt_input() {
    local message="${1:-Enter value:}"
    local default="${2:-}"
    local result
    
    case "$_PROMPT_TOOL" in
        whiptail)
            result=$(whiptail --inputbox "$message" 8 40 "$default" 3>&1 1>&2 2>&3)
            [ $? -eq 0 ] && echo "$result" || echo "$default"
            ;;
        dialog)
            result=$(dialog --inputbox "$message" 8 40 "$default" --stdout 2>/dev/null)
            echo "${result:-$default}"
            ;;
        *)
            read -p "$message " result
            echo "${result:-$default}"
            ;;
    esac
}

# Prompt for selection (single choice)
prompt_select() {
    local message="${1:-Select option:}"
    shift
    local options=("$@")
    local result
    
    case "$_PROMPT_TOOL" in
        whiptail)
            local menu_args=()
            local i=1
            for opt in "${options[@]}"; do
                menu_args+=("$i" "$opt")
                ((i++))
            done
            local choice
            choice=$(whiptail --menu "$message" 15 40 "${#options[@]}" "${menu_args[@]}" 3>&1 1>&2 2>&3)
            [ -n "$choice" ] && echo "${options[$((choice-1))]}"
            ;;
        dialog)
            local menu_args=()
            local i=1
            for opt in "${options[@]}"; do
                menu_args+=("$i" "$opt")
                ((i++))
            done
            choice=$(dialog --menu "$message" 15 40 "${#options[@]}" "${menu_args[@]}" --stdout 2>/dev/null)
            [ -n "$choice" ] && echo "${options[$((choice-1))]}"
            ;;
        fzf)
            printf '%s\n' "${options[@]}" | fzf --prompt "$message " --height 40% --select-1
            ;;
        *)
            echo "Select an option:" >&2
            select opt in "${options[@]}"; do
                [ -n "$opt" ] && echo "$opt" && break
            done
            ;;
    esac
}

# Prompt for confirmation (yes/no)
prompt_confirm() {
    local message="${1:-Continue?}"
    local result
    
    case "$_PROMPT_TOOL" in
        whiptail)
            whiptail --yesno "$message" 8 40
            return $?
            ;;
        dialog)
            dialog --yesno "$message" 8 40
            return $?
            ;;
        *)
            read -p "$message (y/N): " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]]
            return $?
            ;;
    esac
}

# Prompt for password (hidden input)
prompt_password() {
    local message="${1:-Enter password:}"
    local result
    
    case "$_PROMPT_TOOL" in
        whiptail)
            result=$(whiptail --passwordbox "$message" 8 40 3>&1 1>&2 2>&3)
            [ $? -eq 0 ] && echo "$result"
            ;;
        dialog)
            dialog --passwordbox "$message" 8 40 --stdout 2>/dev/null
            ;;
        *)
            read -s -p "$message " result
            echo
            echo "$result"
            ;;
    esac
}

# Multi-select (checklist)
prompt_multiselect() {
    local message="${1:-Select options:}"
    shift
    local options=("$@")
    local result
    
    case "$_PROMPT_TOOL" in
        whiptail)
            local checklist_args=()
            local i=1
            for opt in "${options[@]}"; do
                checklist_args+=("$i" "$opt" "OFF")
                ((i++))
            done
            local choices
            choices=$(whiptail --checklist "$message" 15 40 "${#options[@]}" "${checklist_args[@]}" 3>&1 1>&2 2>&3)
            # Parse output (whiptail returns "1" "2" format)
            if [ -n "$choices" ]; then
                echo "$choices" | tr ' ' '\n' | sed 's/"//g' | while read -r idx; do
                    echo "${options[$((idx-1))]}"
                done
            fi
            ;;
        dialog)
            local checklist_args=()
            local i=1
            for opt in "${options[@]}"; do
                checklist_args+=("$i" "$opt" "OFF")
                ((i++))
            done
            choices=$(dialog --checklist "$message" 15 40 "${#options[@]}" "${checklist_args[@]}" --stdout 2>/dev/null)
            if [ -n "$choices" ]; then
                echo "$choices" | tr ' ' '\n' | sed 's/"//g' | while read -r idx; do
                    echo "${options[$((idx-1))]}"
                done
            fi
            ;;
        fzf)
            printf '%s\n' "${options[@]}" | fzf --multi --prompt "$message " --height 40%
            ;;
        *)
            echo "Select options (space to toggle, enter when done):" >&2
            local selected=()
            for opt in "${options[@]}"; do
                read -p "Select $opt? (y/N): " -n 1 -r
                echo
                [[ $REPLY =~ ^[Yy]$ ]] && selected+=("$opt")
            done
            printf '%s\n' "${selected[@]}"
            ;;
    esac
}

# If script is executed directly, show usage
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    cat << EOF
Prompt Helper - Interactive prompts for bash scripts

Usage:
    source prompt.sh
    
    # Then use functions:
    NAME=\$(prompt_input "What is your name?")
    COLOR=\$(prompt_select "Choose color:" "Red" "Blue" "Green")
    if prompt_confirm "Continue?"; then echo "Yes"; fi
    PASS=\$(prompt_password "Enter password:")
    SELECTED=\$(prompt_multiselect "Choose options:" "Opt1" "Opt2" "Opt3")

Available tools (auto-detected): $_PROMPT_TOOL
EOF
fi

