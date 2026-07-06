#!/bin/bash

# --- UNIVERSAL HYPRLAND DOTFILES INSTALLER ---
# This script is meant to COPY AND PASTE your configurations.
# It assumes you already have Hyprland and its components installed.

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Hyprland Dotfiles Installation...${NC}"

# Function to check if a command exists
check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        echo -e "${GREEN}[OK]${NC} $1 is installed."
        return 0
    else
        echo -e "${RED}[MISSING]${NC} $1 is not found in your PATH."
        return 1
    fi
}

# List of essential components to check
COMPONENTS=(
    "hyprland"
    "waybar"
    "kitty"
    "fish"
    "rofi"
    "swaync"
    "hyprlock"
    "thunar"
    "brave"
    "grim"
    "slurp"
    "wl-copy"
    "brightnessctl"
    "playerctl"
    "nwg-look"
    "kvantummanager"
)

MISSING_COUNT=0

echo -e "\n${YELLOW}Checking for required components...${NC}"
for cmd in "${COMPONENTS[@]}"; do
    if ! check_cmd "$cmd"; then
        ((MISSING_COUNT++))
    fi
done

if [ $MISSING_COUNT -gt 0 ]; then
    echo -e "\n${RED}Warning:${NC} $MISSING_COUNT components are missing."
    echo -e "Please install them using your package manager (e.g., apt, pacman, emerge) before continuing."
    read -p "Do you want to proceed with copying the config files anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation aborted."
        exit 1
    fi
fi

# Create target directories
echo -e "\n${YELLOW}Creating configuration directories...${NC}"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.themes"
mkdir -p "$HOME/.local/share/fonts"

# Copy configurations
echo -e "${YELLOW}Copying dotfiles to ~/.config/...${NC}"
CONFIG_DIR="$(dirname "$0")/config"

if [ -d "$CONFIG_DIR" ]; then
    cp -rv "$CONFIG_DIR"/* "$HOME/.config/"
    echo -e "${GREEN}Done!${NC} Configurations copied."
else
    echo -e "${RED}Error:${NC} 'config' directory not found in the current folder."
    exit 1
fi

# Copy themes
echo -e "${YELLOW}Copying themes to ~/.themes/...${NC}"
THEME_DIR="$(dirname "$0")/themes"
if [ -d "$THEME_DIR" ]; then
    cp -rv "$THEME_DIR"/* "$HOME/.themes/"
    echo -e "${GREEN}Done!${NC} Themes copied."
fi

# Copy fonts
echo -e "${YELLOW}Installing fonts...${NC}"
FONT_DIR="$(dirname "$0")/fonts"
if [ -d "$FONT_DIR" ]; then
    cp -rv "$FONT_DIR"/* "$HOME/.local/share/fonts/"
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f
        echo -e "${GREEN}Done!${NC} Font cache updated."
    fi
fi

echo -e "\n${GREEN}Installation Complete!${NC}"
echo -e "Please restart Hyprland to apply the changes."
