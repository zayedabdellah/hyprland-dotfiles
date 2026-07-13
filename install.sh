#!/bin/bash

# --- UNIVERSAL HYPRLAND DOTFILES INSTALLER ---
# This script is meant to COPY AND PASTE your configurations.
# Now with Arch Linux auto-install support (excluding Brave).

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

# Mapping of commands to Arch Linux package names
declare -A ARCH_PKGS=(
    ["hyprland"]="hyprland"
    ["waybar"]="waybar"
    ["kitty"]="kitty"
    ["fish"]="fish"
    ["rofi"]="rofi"
    ["swaync"]="swaync"
    ["hyprlock"]="hyprlock"
    ["thunar"]="thunar"
    ["grim"]="grim"
    ["slurp"]="slurp"
    ["wl-copy"]="wl-clipboard"
    ["brightnessctl"]="brightnessctl"
    ["playerctl"]="playerctl"
    ["nwg-look"]="nwg-look"
    ["kvantummanager"]="kvantum"
    ["awww-daemon"]="awww"
    ["polkit-kde-agent"]="polkit-kde-agent"
    ["qt6ct"]="qt6ct"
    ["qt5ct"]="qt5ct"
    ["pavucontrol-qt"]="pavucontrol-qt"
    ["nmtui"]="networkmanager"
    ["btop"]="btop"
    ["noto-fonts"]="noto-fonts"
    ["noto-fonts-cjk"]="noto-fonts-cjk"
    ["noto-fonts-emoji"]="noto-fonts-emoji"
    ["noto-fonts-extra"]="noto-fonts-extra"
)

COMPONENTS=("hyprland" "waybar" "kitty" "fish" "rofi" "swaync" "hyprlock" "thunar" "grim" "slurp" "wl-copy" "brightnessctl" "playerctl" "nwg-look" "kvantummanager" "awww-daemon" "qt6ct" "qt5ct" "pavucontrol-qt" "nmtui" "btop" "noto-fonts" "noto-fonts-cjk" "noto-fonts-emoji" "noto-fonts-extra" "polkit-kde-agent")
MISSING_PKGS=()

echo -e "\n${YELLOW}Checking for required components...${NC}"
for cmd in "${COMPONENTS[@]}"; do
    if ! check_cmd "$cmd"; then
        MISSING_PKGS+=("${ARCH_PKGS[$cmd]}")
    fi
done

# Check for Brave separately (as requested to exclude from auto-install)
if ! check_cmd "brave"; then
    echo -e "${YELLOW}Note:${NC} Brave Browser is missing but will not be auto-installed."
fi

# Arch Auto-Install Logic
if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    if [ -f /etc/arch-release ]; then
        echo -e "\n${YELLOW}Arch Linux detected!${NC}"
        read -p "Would you like to auto-install the missing packages? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installing missing packages...${NC}"
            sudo pacman -S --needed --noconfirm "${MISSING_PKGS[@]}"
        fi
    else
        echo -e "\n${RED}Warning:${NC} ${#MISSING_PKGS[@]} components are missing."
        echo -e "Since you are not on Arch Linux, please install the following packages manually:"
        echo -e "${YELLOW}-----------------------------------------${NC}"
        for pkg in "${MISSING_PKGS[@]}"; do
            echo -e " - $pkg"
        done
        echo -e "${YELLOW}-----------------------------------------${NC}"
        echo -e "Note: Package names may vary depending on your distribution."
        
        read -p "Do you want to proceed with copying the config files anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation aborted."
            exit 1
        fi
    fi
fi

# Create target directories
echo -e "\n${YELLOW}Creating configuration directories...${NC}"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.themes"
mkdir -p "$HOME/.local/share/fonts"
mkdir -p "$HOME/.local/bin"

# Copy configurations
echo -e "${YELLOW}Copying dotfiles to ~/.config/...${NC}"
CONFIG_DIR="$(dirname "$0")/config"
if [ -d "$CONFIG_DIR" ]; then
    cp -rv "$CONFIG_DIR"/* "$HOME/.config/"
    echo -e "${GREEN}Done!${NC} Configurations copied."
else
    echo -e "${RED}Error:${NC} 'config' directory not found."
    exit 1
fi

# Copy themes
echo -e "${YELLOW}Copying themes to ~/.themes/...${NC}"
THEME_DIR="$(dirname "$0")/themes"
if [ -d "$THEME_DIR" ]; then
    cp -rv "$THEME_DIR"/* "$HOME/.themes/"
    echo -e "${GREEN}Done!${NC} Themes copied."
    echo -e "${YELLOW}Setting up Kvantum themes...${NC}"
    mkdir -p "$HOME/.config/Kvantum"
    cp -rv "$THEME_DIR"/gruvbox-kvantum "$HOME/.config/Kvantum/"
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

# Copy scripts
echo -e "${YELLOW}Installing scripts...${NC}"
SCRIPT_DIR="$(dirname "$0")/scripts"
if [ -d "$SCRIPT_DIR" ]; then
    cp -rv "$SCRIPT_DIR"/* "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/"*
    echo -e "${GREEN}Done!${NC} Scripts installed."
fi

# Apply GTK settings
echo -e "${YELLOW}Applying GTK settings...${NC}"
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme 'gruvbox-dark-gtk'
    gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 11'
    gsettings set org.gnome.desktop.interface document-font-name 'JetBrainsMono Nerd Font 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
    echo -e "${GREEN}Done!${NC} GTK settings applied."
fi

# Apply Wallpaper using awww
echo -e "${YELLOW}Setting wallpaper...${NC}"
if command -v awww >/dev/null 2>&1; then
    # Start daemon in background if not running
    if ! pgrep -x "awww-daemon" > /dev/null; then
        awww-daemon &
        sleep 2
    fi
    awww img "$HOME/.config/hypr/wallpapers/wallpaper.jpg"
    echo -e "${GREEN}Done!${NC} Wallpaper set."
fi

echo -e "\n${GREEN}Installation Complete!${NC}"
echo -e "${YELLOW}Note:${NC} To apply the Chrome theme, go to chrome://extensions, enable 'Developer mode', and 'Load unpacked' from ~/.config/google-chrome/themes/fjofdcgahcnlkdjapcbeonbnmjdnfcki"
echo -e "Please restart Hyprland to apply the changes."
