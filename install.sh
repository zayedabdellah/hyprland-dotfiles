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

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OPTIONAL_MODULES=()

usage() {
    cat <<'EOF'
Usage: ./install.sh [--enable-optional MODULE]...

Core configuration is deployed by default. Optional modules are never copied
unless explicitly enabled. Package-manager and backup/restore orchestration
remain future phases of this installer.

Modules: retroarch sunshine dolphin-emu suyu goverlay vkBasalt vkSumi pavucontrol mimeapps
EOF
}

while (($# > 0)); do
    case "$1" in
        --enable-optional)
            [[ $# -ge 2 ]] || { echo "Missing module after --enable-optional" >&2; usage >&2; exit 2; }
            OPTIONAL_MODULES+=("$2")
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

for module in "${OPTIONAL_MODULES[@]}"; do
    case "$module" in
        retroarch|sunshine|dolphin-emu|suyu|goverlay|vkBasalt|vkSumi|mimeapps|pavucontrol)
            ;;
        *)
            echo "Unknown optional module: $module" >&2
            usage >&2
            exit 2
            ;;
    esac
done

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
    ["qt6ct"]="qt6ct"
    ["qt5ct"]="qt5ct"
    ["pavucontrol-qt"]="pavucontrol-qt"
    ["nmtui"]="networkmanager"
    ["btop"]="btop"
    ["hyprpolkitagent"]="hyprpolkitagent"
    ["polkit-kde-agent"]="polkit-kde-agent"
)

COMPONENTS=("hyprland" "waybar" "kitty" "fish" "rofi" "swaync" "hyprlock" "thunar" "grim" "slurp" "wl-copy" "brightnessctl" "playerctl" "nwg-look" "kvantummanager" "awww-daemon" "qt6ct" "qt5ct" "pavucontrol-qt" "nmtui" "btop" "hyprpolkitagent" "polkit-kde-agent")
MISSING_PKGS=()

echo -e "\n${YELLOW}Checking for required components...${NC}"
for cmd in "${COMPONENTS[@]}"; do
    if ! check_cmd "$cmd"; then
        MISSING_PKGS+=("${ARCH_PKGS[$cmd]}")
    fi
done

if ! find "$HOME/.local/share/icons" /usr/share/icons /usr/local/share/icons \
    -maxdepth 2 -type f -path '*/Papirus-Dark/index.theme' -print -quit 2>/dev/null | grep -q .; then
    echo -e "${RED}[MISSING]${NC} Papirus-Dark icon theme is required by GTK, Qt, and xsettingsd."
    MISSING_PKGS+=("papirus-icon-theme")
else
    echo -e "${GREEN}[OK]${NC} Papirus-Dark icon theme is installed."
fi

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
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.local/share/applications"

copy_tree() {
    local source="$1" destination="$2"
    mkdir -p "$destination"
    cp -a "$source"/. "$destination"/
}

copy_file() {
    local source="$1" destination="$2"
    mkdir -p "$(dirname -- "$destination")"
    cp -a "$source" "$destination"
}

CONFIG_DIR="$SCRIPT_ROOT/config"

# Copy only core configuration. In particular, this excludes config/optional,
# Brave profiles, and the local application directory until explicitly enabled.
CORE_CONFIG_DIRS=(Kvantum MangoHud Thunar btop cava fish gtk-3.0 gtk-4.0 hypr kitty mpv oh-my-posh rofi swaync waybar xsettingsd)
for component in "${CORE_CONFIG_DIRS[@]}"; do
    if [[ -d "$CONFIG_DIR/$component" ]]; then
        echo -e "${YELLOW}Copying $component to ~/.config/$component...${NC}"
        copy_tree "$CONFIG_DIR/$component" "$HOME/.config/$component"
    fi
done
copy_file "$CONFIG_DIR/kdeglobals" "$HOME/.config/kdeglobals"
echo -e "${GREEN}Core configurations copied.${NC}"

# Copy themes
echo -e "${YELLOW}Copying themes to ~/.themes/...${NC}"
THEME_DIR="$SCRIPT_ROOT/themes"
if [ -d "$THEME_DIR" ]; then
    copy_tree "$THEME_DIR" "$HOME/.themes"
    echo -e "${GREEN}Done!${NC} Themes copied."
fi

# Copy fonts
echo -e "${YELLOW}Installing fonts...${NC}"
FONT_DIR="$SCRIPT_ROOT/fonts"
if [ -d "$FONT_DIR" ]; then
    copy_tree "$FONT_DIR" "$HOME/.local/share/fonts"
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f
        echo -e "${GREEN}Done!${NC} Font cache updated."
    fi
fi

# Copy the explicitly approved cursor/icon assets.
ICON_DIR="$SCRIPT_ROOT/icons"
if [ -d "$ICON_DIR" ]; then
    copy_tree "$ICON_DIR" "$HOME/.local/share/icons"
fi

# Copy scripts
echo -e "${YELLOW}Installing scripts...${NC}"
SCRIPT_DIR="$SCRIPT_ROOT/scripts"
if [ -d "$SCRIPT_DIR" ]; then
    copy_tree "$SCRIPT_DIR" "$HOME/.local/bin"
    find "$HOME/.local/bin" -maxdepth 1 -type f -exec chmod +x {} +
    echo -e "${GREEN}Done!${NC} Scripts installed."
fi

install_optional() {
    local module="$1"
    case "$module" in
        retroarch)
            copy_file "$CONFIG_DIR/optional/retroarch/appearance.cfg" "$HOME/.config/retroarch/appearance.cfg" ;;
        sunshine)
            copy_file "$CONFIG_DIR/optional/sunshine/apps.json" "$HOME/.config/sunshine/apps.json" ;;
        dolphin-emu)
            copy_file "$CONFIG_DIR/optional/dolphin-emu/appearance.ini" "$HOME/.config/dolphin-emu/appearance.ini"
            copy_file "$CONFIG_DIR/local/share/applications/dolphin-emu.desktop" "$HOME/.local/share/applications/dolphin-emu.desktop" ;;
        suyu)
            copy_file "$CONFIG_DIR/optional/suyu/appearance.ini" "$HOME/.config/suyu/appearance.ini" ;;
        goverlay)
            copy_file "$CONFIG_DIR/optional/goverlay/goverlay.conf" "$HOME/.config/goverlay/goverlay.conf" ;;
        vkBasalt)
            copy_file "$CONFIG_DIR/optional/vkBasalt/vkBasalt.conf" "$HOME/.config/vkBasalt/vkBasalt.conf" ;;
        vkSumi)
            copy_file "$CONFIG_DIR/optional/vkSumi/vkSumi.conf" "$HOME/.config/vkSumi/vkSumi.conf" ;;
        mimeapps)
            copy_file "$CONFIG_DIR/optional/mimeapps.list" "$HOME/.config/mimeapps.list" ;;
        pavucontrol)
            echo "No reusable Pavucontrol preference file was found; nothing to deploy." ;;
        *)
            echo "Unknown optional module: $module" >&2
            return 2 ;;
    esac
}

for module in "${OPTIONAL_MODULES[@]}"; do
    echo -e "${YELLOW}Enabling optional module: $module${NC}"
    install_optional "$module"
done

# Apply GTK settings
echo -e "${YELLOW}Applying GTK settings...${NC}"
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme 'gruvbox-dark-gtk'
    gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 11'
    gsettings set org.gnome.desktop.interface document-font-name 'JetBrainsMono Nerd Font 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
    echo -e "${GREEN}Done!${NC} GTK settings applied."
fi

# Note: Wallpaper is applied automatically via autostart.lua once you log into Hyprland.

echo -e "\n${GREEN}Installation Complete!${NC}"
echo -e "${YELLOW}Note:${NC} Brave theme installation is manual; see config/brave/README.md."
echo -e "Please restart Hyprland to apply the changes."
