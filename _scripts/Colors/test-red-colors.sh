#!/usr/bin/env bash
# Test different red color combinations for BG and FG

echo "Red Color Combinations - Dark BG with Bright FG"
echo "================================================"
echo ""

# Dark red backgrounds to test (1 is darkest, then 52, etc.)
dark_reds=("1" "52" "88" "124" "160" "196")

# Bright red foregrounds to test
bright_reds=("9" "196" "203" "204" "205" "210" "211" "214")

for bg in "${dark_reds[@]}"; do
    for fg in "${bright_reds[@]}"; do
        printf "\033[48;5;%sm\033[38;5;%sm  No  \033[0m  " "$bg" "$fg"
    done
    echo ""
    for fg in "${bright_reds[@]}"; do
        printf "\033[48;5;%sm\033[38;5;%sm BG:%3s\033[0m  " "$bg" "$fg" "$bg"
    done
    echo ""
    for fg in "${bright_reds[@]}"; do
        printf "\033[48;5;%sm\033[38;5;%sm FG:%3s\033[0m  " "$bg" "$fg" "$fg"
    done
    echo ""
    echo ""
done

echo ""
echo "Using darker red backgrounds (1, 52) with different bright red foregrounds:"
echo "============================================================================"
echo ""

for bg in "1" "52"; do
    echo "BG: $bg"
    for fg in "${bright_reds[@]}"; do
        printf "\033[48;5;%sm\033[38;5;%sm  No  \033[0m  " "$bg" "$fg"
    done
    echo ""
    for fg in "${bright_reds[@]}"; do
        printf "\033[48;5;%sm\033[38;5;%sm FG:%3s\033[0m  " "$bg" "$fg" "$fg"
    done
    echo ""
    echo ""
done

echo "Legend:"
echo "  BG = Background color code (1 is darkest red, 52 is dark red)"
echo "  FG = Foreground color code"
echo ""

