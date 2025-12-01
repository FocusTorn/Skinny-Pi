#!/usr/bin/env bash
# DietPi Swap Configuration Script
# Uses DietPi's built-in swap management system for optimized configuration

set -e

SWAP_SIZE_MB="${1:-1024}"  # Default to 1GB if not specified
SWAP_LOCATION="${2:-/var/swap}"  # DietPi's standard location

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "═══════════════════════════════════════════════════════════════"
echo "DietPi Swap Configuration"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Please run as root${NC}"
    echo "Usage: sudo $0 [size_in_mb] [location]"
    exit 1
fi

# Check if DietPi swap function exists
if [ ! -f "/boot/dietpi/func/dietpi-set_swapfile" ]; then
    echo -e "${RED}Error: DietPi swap function not found${NC}"
    echo "This script requires DietPi's built-in swap management system."
    exit 1
fi

# Show current status
echo "Current Swap Status:"
echo "────────────────────"
free -h | grep -E "Mem|Swap"
echo ""
swapon --show 2>/dev/null || echo "No swap currently active"
echo ""

# Show current DietPi config
echo "Current DietPi Configuration:"
echo "─────────────────────────────"
if grep -q "^AUTO_SETUP_SWAPFILE_SIZE=" /boot/dietpi.txt; then
    grep "^AUTO_SETUP_SWAPFILE_SIZE=" /boot/dietpi.txt
    grep "^AUTO_SETUP_SWAPFILE_LOCATION=" /boot/dietpi.txt || echo "AUTO_SETUP_SWAPFILE_LOCATION=/var/swap (default)"
else
    echo "AUTO_SETUP_SWAPFILE_SIZE=0 (not configured)"
    echo "AUTO_SETUP_SWAPFILE_LOCATION=/var/swap (default)"
fi
echo ""

# Validate swap size
if ! [[ "$SWAP_SIZE_MB" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid swap size '$SWAP_SIZE_MB'${NC}"
    echo "Size must be a number in MiB (e.g., 1024 for 1GB)"
    exit 1
fi

if [ "$SWAP_SIZE_MB" -eq 0 ]; then
    echo -e "${YELLOW}Swap size is 0 - this will disable swap${NC}"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Show what will be configured
echo "Configuration Plan:"
echo "───────────────────"
echo "Swap Size: ${SWAP_SIZE_MB} MiB ($(echo "scale=2; $SWAP_SIZE_MB/1024" | bc) GB)"
echo "Location: $SWAP_LOCATION"
echo "Method: DietPi built-in swap management"
echo ""

read -p "Apply this configuration? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Configuring swap..."
echo ""

# Update DietPi configuration file
if grep -q "^AUTO_SETUP_SWAPFILE_SIZE=" /boot/dietpi.txt; then
    sed -i "s/^AUTO_SETUP_SWAPFILE_SIZE=.*/AUTO_SETUP_SWAPFILE_SIZE=$SWAP_SIZE_MB/" /boot/dietpi.txt
else
    echo "AUTO_SETUP_SWAPFILE_SIZE=$SWAP_SIZE_MB" >> /boot/dietpi.txt
fi

if grep -q "^AUTO_SETUP_SWAPFILE_LOCATION=" /boot/dietpi.txt; then
    sed -i "s|^AUTO_SETUP_SWAPFILE_LOCATION=.*|AUTO_SETUP_SWAPFILE_LOCATION=$SWAP_LOCATION|" /boot/dietpi.txt
else
    echo "AUTO_SETUP_SWAPFILE_LOCATION=$SWAP_LOCATION" >> /boot/dietpi.txt
fi

# Run DietPi's swap setup function
echo "Running DietPi swap setup function..."
if /boot/dietpi/func/dietpi-set_swapfile "$SWAP_SIZE_MB" "$SWAP_LOCATION"; then
    echo ""
    echo -e "${GREEN}✅ Swap configured successfully!${NC}"
    echo ""
    echo "New Swap Status:"
    echo "────────────────"
    free -h | grep -E "Mem|Swap"
    echo ""
    swapon --show
    echo ""
    echo "Swappiness setting:"
    sysctl vm.swappiness
    echo ""
    echo -e "${GREEN}Swap will persist across reboots.${NC}"
else
    echo ""
    echo -e "${RED}❌ Error configuring swap${NC}"
    exit 1
fi

