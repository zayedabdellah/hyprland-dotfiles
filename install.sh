#!/bin/bash

# --- UNIVERSAL HYPRLAND DOTFILES INSTALLER ---
# This script is meant to COPY AND PASTE your configurations.
# Package installation is opt-in and distribution-aware; Brave is excluded.

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OPTIONAL_MODULES=()
DRY_RUN=0
AUDIT_ONLY=0
SKIP_PACKAGES=0
SET_DEFAULT_SHELL=0
NON_INTERACTIVE=0
APPLY_DESKTOP_SETTINGS=0
PROFILE_NAME=""
PROFILE_EXPLICIT=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Core configuration is deployed by default. Optional modules are never copied
unless explicitly enabled.

Options:
  --enable-optional MODULE  Enable one optional module (repeatable)
  --audit                   Inspect dependencies without deploying files
  --dry-run                 Show actions without changing files
  --skip-packages           Do not install packages; continue with deployment
  --set-default-shell       Ask before changing this user's login shell to Fish
  --apply-desktop-settings  Apply GTK settings through gsettings
  --profile PROFILE         Select zayed-laptop or generic
  --non-interactive         Never prompt; unspecified profile uses generic
  --help                    Show this help

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
        --audit)
            AUDIT_ONLY=1
            DRY_RUN=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --skip-packages)
            SKIP_PACKAGES=1
            shift
            ;;
        --set-default-shell)
            SET_DEFAULT_SHELL=1
            shift
            ;;
        --apply-desktop-settings)
            APPLY_DESKTOP_SETTINGS=1
            shift
            ;;
        --profile)
            [[ $# -ge 2 ]] || { echo "Missing profile after --profile" >&2; usage >&2; exit 2; }
            PROFILE_NAME="$2"
            PROFILE_EXPLICIT=1
            shift 2
            ;;
        --non-interactive)
            NON_INTERACTIVE=1
            shift
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

case "$PROFILE_NAME" in
    "") ;;
    zayed-laptop|generic) ;;
    *) echo "Invalid profile '$PROFILE_NAME'; choose zayed-laptop or generic." >&2; exit 2 ;;
esac

if (( ! PROFILE_EXPLICIT )) && [[ -n "${DOTFILES_MACHINE_PROFILE:-}" ]]; then
    PROFILE_NAME="$DOTFILES_MACHINE_PROFILE"
    PROFILE_EXPLICIT=1
    case "$PROFILE_NAME" in
        zayed-laptop|generic) ;;
        *) echo "Invalid DOTFILES_MACHINE_PROFILE '$PROFILE_NAME'; choose zayed-laptop or generic." >&2; exit 2 ;;
    esac
fi

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

declare -A GENTOO_PKGS=(
    [hyprland]="gui-wm/hyprland"
    [waybar]="gui-apps/waybar"
    [kitty]="app-emulation/kitty"
    [fish]="app-shells/fish"
    [rofi]="gui-apps/rofi"
    [thunar]="xfce-base/thunar"
    [grim]="gui-apps/grim"
    [slurp]="gui-apps/slurp"
    [wl-copy]="gui-apps/wl-clipboard"
    [brightnessctl]="sys-power/brightnessctl"
    [playerctl]="media-sound/playerctl"
    [kvantummanager]="x11-themes/kvantum"
    [qt6ct]="gui-apps/qt6ct"
    [nmtui]="net-misc/networkmanager"
    [btop]="app-misc/btop"
    [curl]="net-misc/curl"
    [unzip]="app-arch/unzip"
    [realpath]="sys-apps/coreutils"
    [dirname]="sys-apps/coreutils"
)

declare -A GENTOO_USE_FLAGS=(
    [waybar]="network wifi tray mpris pipewire pulseaudio upower"
    [hyprland]="qtutils"
    [kvantummanager]="kde"
)

declare -A GENTOO_OVERLAY_NOTES=(
    [hyprland]="Current Hyprland releases may require hyproverlay; do not enable it automatically."
    [hyprlock]="No verified ::gentoo atom was found; check hyproverlay or build manually."
    [awww-daemon]="No verified ::gentoo atom was found; check hyproverlay or build manually."
    [hyprpolkitagent]="No verified ::gentoo atom was found; check hyproverlay or build manually."
)

declare -A FEDORA_PKGS=(
    [fish]="fish"
    [curl]="curl"
    [unzip]="unzip"
    [realpath]="coreutils"
    [dirname]="coreutils"
)

DISTRO_ID="${DOTFILES_DISTRO_ID:-unknown}"
if [[ -z "${DOTFILES_DISTRO_ID:-}" && -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
fi

package_name() {
    local command_name="$1"
    case "$DISTRO_ID" in
        arch|manjaro) printf '%s' "${ARCH_PKGS[$command_name]:-$command_name}" ;;
        gentoo) printf '%s' "${GENTOO_PKGS[$command_name]:-}" ;;
        fedora|nobara) printf '%s' "${FEDORA_PKGS[$command_name]:-}" ;;
        *) printf '%s' "" ;;
    esac
}

COMPONENTS=("hyprland" "waybar" "kitty" "fish" "rofi" "swaync" "hyprlock" "thunar" "grim" "slurp" "wl-copy" "brightnessctl" "playerctl" "nwg-look" "kvantummanager" "awww-daemon" "qt6ct" "qt5ct" "pavucontrol-qt" "nmtui" "btop" "hyprpolkitagent" "polkit-kde-agent")
MISSING_PKGS=()
GENTOO_UNMAPPED=()
UNMAPPED_COMPONENTS=()

record_missing() {
    local command_name="$1" package
    package="$(package_name "$command_name")"
    if [[ -n "$package" ]]; then
        MISSING_PKGS+=("$package")
    elif [[ "$DISTRO_ID" == "gentoo" ]]; then
        GENTOO_UNMAPPED+=("$command_name")
    else
        UNMAPPED_COMPONENTS+=("$command_name")
    fi
}

echo -e "\n${YELLOW}Checking for required components...${NC}"
for cmd in "${COMPONENTS[@]}"; do
    if ! check_cmd "$cmd"; then
        record_missing "$cmd"
    fi
done

if [[ ! -x "$HOME/.local/bin/oh-my-posh" ]] && ! command -v oh-my-posh >/dev/null 2>&1; then
    for helper in curl unzip realpath dirname; do
        if ! command -v "$helper" >/dev/null 2>&1; then
            record_missing "$helper"
        fi
    done
fi

if ! find "$HOME/.local/share/icons" /usr/share/icons /usr/local/share/icons \
    -maxdepth 2 -type f -path '*/Papirus-Dark/index.theme' -print -quit 2>/dev/null | grep -q .; then
    echo -e "${RED}[MISSING]${NC} Papirus-Dark icon theme is required by GTK, Qt, and xsettingsd."
    case "$DISTRO_ID" in
        gentoo) GENTOO_UNMAPPED+=("Papirus-Dark icon theme (no verified atom in this audit)") ;;
        fedora|nobara) UNMAPPED_COMPONENTS+=("Papirus-Dark icon theme") ;;
        *) MISSING_PKGS+=("papirus-icon-theme") ;;
    esac
else
    echo -e "${GREEN}[OK]${NC} Papirus-Dark icon theme is installed."
fi

# Check for Brave separately (as requested to exclude from auto-install)
if ! check_cmd "brave"; then
    echo -e "${YELLOW}Note:${NC} Brave Browser is missing but will not be auto-installed."
fi

# Package installation is explicit and distribution-aware. The repository
# never changes packages during an audit or dry run.
if (( ${#MISSING_PKGS[@]} > 0 || ${#UNMAPPED_COMPONENTS[@]} > 0 || ${#GENTOO_UNMAPPED[@]} > 0 )); then
    echo -e "\n${YELLOW}Missing dependencies on $DISTRO_ID:${NC}"
    if (( ${#MISSING_PKGS[@]} > 0 )); then
        printf ' - %s\n' "${MISSING_PKGS[@]}"
    fi
    if (( ${#UNMAPPED_COMPONENTS[@]} > 0 )); then
        echo "No verified package mapping; skipped automatic installation for:"
        printf ' - %s\n' "${UNMAPPED_COMPONENTS[@]}"
    fi
    if [[ "$DISTRO_ID" == "gentoo" && ${#GENTOO_UNMAPPED[@]} -gt 0 ]]; then
        echo "Gentoo atoms not verified; skipped automatic installation for:"
        printf ' - %s\n' "${GENTOO_UNMAPPED[@]}"
        for command_name in "${GENTOO_UNMAPPED[@]}"; do
            if [[ -n "${GENTOO_OVERLAY_NOTES[$command_name]:-}" ]]; then
                echo "   ${GENTOO_OVERLAY_NOTES[$command_name]}"
            fi
        done
    fi
    if [[ "$DISTRO_ID" == "gentoo" ]]; then
        echo "Suggested Portage review only (not applied):"
        for command_name in waybar hyprland kvantummanager; do
            if [[ -n "${GENTOO_USE_FLAGS[$command_name]:-}" ]]; then
                echo "  ${GENTOO_PKGS[$command_name]} USE=\"${GENTOO_USE_FLAGS[$command_name]}\""
            fi
        done
        echo "  Current Hyprland releases may require hyproverlay; enable it manually only after review."
    fi
    if (( SKIP_PACKAGES || DRY_RUN || NON_INTERACTIVE )); then
        echo -e "${YELLOW}Package changes skipped by --skip-packages/--dry-run/--non-interactive.${NC}"
    elif [[ "$DISTRO_ID" == "arch" || "$DISTRO_ID" == "manjaro" ]]; then
        read -r -p "Install verified missing packages with sudo pacman? (y/n) " reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            (( ${#MISSING_PKGS[@]} == 0 )) || sudo pacman -S --needed --noconfirm "${MISSING_PKGS[@]}"
        fi
    elif [[ "$DISTRO_ID" == "gentoo" ]]; then
        read -r -p "Install verified Gentoo atoms with sudo emerge? (y/n) " reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            (( ${#MISSING_PKGS[@]} == 0 )) || sudo emerge --ask "${MISSING_PKGS[@]}"
        fi
    elif [[ "$DISTRO_ID" == "fedora" || "$DISTRO_ID" == "nobara" ]]; then
        echo "Fedora support is experimental; no automatic dnf/dnf5 changes are performed."
    elif [[ "$DISTRO_ID" == "nixos" ]]; then
        echo "NixOS package changes belong in flake/home-manager configuration; no imperative installation was attempted."
    else
        echo -e "\n${RED}Warning:${NC} ${#MISSING_PKGS[@]} components are missing."
        echo -e "Note: Package names may vary depending on your distribution."
    fi
    if [[ "$DISTRO_ID" != "nixos" && "$DISTRO_ID" != "arch" && "$DISTRO_ID" != "manjaro" && "$DISTRO_ID" != "gentoo" && "$DISTRO_ID" != "fedora" && "$DISTRO_ID" != "nobara" && ! $SKIP_PACKAGES && ! $DRY_RUN && ! $NON_INTERACTIVE ]]; then
        read -r -p "Proceed with copying configuration files anyway? (y/n) " reply
        [[ "$reply" =~ ^[Yy]$ ]] || { echo "Installation aborted."; exit 1; }
    fi
fi

detect_zayed_laptop() {
    local monitor_info="" gpu_info="" dmi_product=""
    if command -v hyprctl >/dev/null 2>&1; then
        monitor_info="$(hyprctl monitors 2>/dev/null | grep -E 'eDP-1|2560x1600|165' || true)"
    elif command -v wlr-randr >/dev/null 2>&1; then
        monitor_info="$(wlr-randr 2>/dev/null | grep -E 'eDP-1|2560x1600|165' || true)"
    fi
    if command -v lspci >/dev/null 2>&1; then
        gpu_info="$(lspci 2>/dev/null | grep -i nvidia || true)"
    fi
    if [[ -r /sys/devices/virtual/dmi/id/product_name ]]; then
        # Product name is non-unique model information; serials and UUIDs are
        # deliberately never read or stored.
        dmi_product="$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true)"
    fi
    [[ "$monitor_info" == *eDP-1* ]] || return 1
    [[ "$monitor_info" == *2560x1600* ]] || return 1
    [[ "$monitor_info" == *165* ]] || return 1
    [[ "$gpu_info" =~ [Nn][Vv][Ii][Dd][Ii][Aa] ]] || return 1
    # If DMI is available, require a readable product name before calling the
    # match exact. The value is never printed, persisted, or compared against
    # a unique identifier.
    [[ ! -r /sys/devices/virtual/dmi/id/product_name || -n "$dmi_product" ]]
}

resolve_profile() {
    if (( PROFILE_EXPLICIT )); then
        echo "Selected machine profile: $PROFILE_NAME"
        return 0
    fi
    if (( NON_INTERACTIVE )) || [[ ! -t 0 ]]; then
        PROFILE_NAME="generic"
        echo "No explicit profile in non-interactive mode; selecting safe generic profile."
        return 0
    fi

    local reply
    if detect_zayed_laptop; then
        read -r -p "Laptop characteristics match eDP-1 2560x1600@165 with NVIDIA. Use zayed-laptop? [Y/n] " reply
        case "$reply" in
            ""|[Yy]*) PROFILE_NAME="zayed-laptop" ;;
            [Nn]*) PROFILE_NAME="generic" ;;
            *) echo "Invalid profile choice; choose zayed-laptop or generic." >&2; return 1 ;;
        esac
    else
        read -r -p "No exact laptop match detected. Choose profile [generic/zayed-laptop] (default generic): " reply
        case "$reply" in
            ""|generic) PROFILE_NAME="generic" ;;
            zayed-laptop) PROFILE_NAME="zayed-laptop" ;;
            *) echo "Invalid profile choice; choose zayed-laptop or generic." >&2; return 1 ;;
        esac
    fi
    echo "Selected machine profile: $PROFILE_NAME"
}

install_oh_my_posh() {
    local target="$HOME/.local/bin/oh-my-posh"
    if [[ -x "$target" ]]; then
        echo -e "${GREEN}[OK]${NC} Oh My Posh: $target"
        return 0
    fi
    if command -v oh-my-posh >/dev/null 2>&1; then
        echo -e "${GREEN}[OK]${NC} Oh My Posh: $(command -v oh-my-posh)"
        return 0
    fi
    if [[ "$DISTRO_ID" == "nixos" ]]; then
        echo "Oh My Posh is missing. Enable programs.oh-my-posh in Home Manager/NixOS instead of downloading it."
        return 0
    fi
    echo -e "${YELLOW}[MISSING]${NC} Oh My Posh"
    local version="${OH_MY_POSH_VERSION:-v29.31.1}"
    echo "Official installer command: curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin -v $version"
    if (( DRY_RUN )); then
        echo "DRY-RUN: Oh My Posh would be installed at $target; no download performed."
        return 0
    fi
    for helper in curl unzip realpath dirname; do
        check_cmd "$helper" || { echo "Oh My Posh requires $helper." >&2; return 1; }
    done
    mkdir -p "$(dirname -- "$target")"
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin" -v "$version"
    [[ -x "$target" ]] || { echo "Oh My Posh installation did not create $target." >&2; return 1; }
}

configure_fish_shell() {
    local fish_path
    fish_path="$(command -v fish || true)"
    if [[ -n "$fish_path" ]]; then
        echo -e "${GREEN}[OK]${NC} Fish executable: $fish_path"
    else
        echo -e "${YELLOW}[MISSING]${NC} Fish executable"
        if (( SET_DEFAULT_SHELL )); then
            if (( DRY_RUN )); then
                echo "DRY-RUN: Fish would need to be installed before changing the login shell; no change performed."
                return 0
            else
                echo "Fish must be installed before --set-default-shell can be used." >&2
                return 1
            fi
        fi
        return 0
    fi
    (( SET_DEFAULT_SHELL )) || return 0
    if (( DRY_RUN )); then
        echo "DRY-RUN: would verify $fish_path in /etc/shells and ask before changing $USER's login shell."
        return 0
    fi
    if (( NON_INTERACTIVE )); then
        echo "--set-default-shell requires an interactive confirmation and cannot be used with --non-interactive." >&2
        return 1
    fi
    if (( EUID == 0 )); then
        echo "Refusing to change root's shell. Run the installer as the target user." >&2
        return 1
    fi
    if [[ "$DISTRO_ID" == "nixos" ]]; then
        echo "NixOS: set users.users.$USER.shell = pkgs.fish; declaratively; no login shell was changed."
        return 0
    fi
    if ! grep -Fxq "$fish_path" /etc/shells 2>/dev/null; then
        read -r -p "Add $fish_path to /etc/shells with sudo? (y/n) " reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
        else
            echo "Fish is not listed in /etc/shells; login shell unchanged." >&2
            return 1
        fi
    fi
    read -r -p "Change only $USER's login shell to $fish_path? (y/n) " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        chsh -s "$fish_path"
    else
        echo "Login shell unchanged."
    fi
}

install_oh_my_posh
configure_fish_shell
resolve_profile

if (( AUDIT_ONLY )); then
    echo "Audit complete; no files were deployed."
    exit 0
fi

# Create target directories
echo -e "\n${YELLOW}Creating configuration directories...${NC}"
if (( ! DRY_RUN )); then
    mkdir -p "$HOME/.config" "$HOME/.themes" "$HOME/.local/share/fonts" \
        "$HOME/.local/bin" "$HOME/.local/share/icons" "$HOME/.local/share/applications"
fi

copy_tree() {
    local source="$1" destination="$2"
    if (( DRY_RUN )); then
        echo "[DRY-RUN] copy directory $source -> $destination"
        return 0
    fi
    mkdir -p "$destination"
    cp -a "$source"/. "$destination"/
}

copy_file() {
    local source="$1" destination="$2"
    if (( DRY_RUN )); then
        echo "[DRY-RUN] copy file $source -> $destination"
        return 0
    fi
    mkdir -p "$(dirname -- "$destination")"
    cp -a "$source" "$destination"
}

persist_profile_selection() {
    local target="$HOME/.config/hypr/machine.local.lua"
    if (( DRY_RUN )); then
        echo "DRY-RUN: would select $PROFILE_NAME in $target; no file written."
        return 0
    fi
    if [[ -e "$target" ]]; then
        echo -e "${YELLOW}Warning:${NC} preserving existing $target; verify it selects '$PROFILE_NAME'."
        return 0
    fi
    mkdir -p "$(dirname -- "$target")"
    printf '%s\n' \
        '-- Generated by dotfiles installer; local and ignored by Git.' \
        "return { profile = \"$PROFILE_NAME\" }" > "$target"
    echo "Selected profile persisted in $target."
}

CONFIG_DIR="$SCRIPT_ROOT/config"
persist_profile_selection

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

# The active Kvantum selector is preserved. If the exact theme payload is
# later licensed and added, deploy it where both Kvantum and the legacy theme
# lookup can discover it. Never substitute kvantum-dark silently.
KVANTUM_THEME_DIR="$SCRIPT_ROOT/themes/gruvbox-kvantum"
if [[ -f "$KVANTUM_THEME_DIR/gruvbox-kvantum.kvconfig" && -f "$KVANTUM_THEME_DIR/gruvbox-kvantum.svg" ]]; then
    copy_file "$KVANTUM_THEME_DIR/gruvbox-kvantum.kvconfig" "$HOME/.config/Kvantum/gruvbox-kvantum/gruvbox-kvantum.kvconfig"
    copy_file "$KVANTUM_THEME_DIR/gruvbox-kvantum.svg" "$HOME/.config/Kvantum/gruvbox-kvantum/gruvbox-kvantum.svg"
    copy_file "$KVANTUM_THEME_DIR/gruvbox-kvantum.kvconfig" "$HOME/.themes/gruvbox-kvantum/gruvbox-kvantum.kvconfig"
    copy_file "$KVANTUM_THEME_DIR/gruvbox-kvantum.svg" "$HOME/.themes/gruvbox-kvantum/gruvbox-kvantum.svg"
else
    echo -e "${YELLOW}Warning:${NC} exact gruvbox-kvantum files are not bundled; install will not substitute another theme."
fi

# Copy themes
echo -e "${YELLOW}Copying themes to ~/.themes/...${NC}"
THEME_DIR="$SCRIPT_ROOT/themes"
if [ -d "$THEME_DIR" ]; then
    copy_tree "$THEME_DIR" "$HOME/.themes"
    copy_file "$THEME_DIR/oh-my-posh/torii-zayed.omp.json" "$HOME/.themes/torii-zayed.omp.json"
    echo -e "${GREEN}Done!${NC} Themes copied."
fi

# Copy fonts
echo -e "${YELLOW}Installing fonts...${NC}"
FONT_DIR="$SCRIPT_ROOT/fonts"
if [ -d "$FONT_DIR" ]; then
    copy_tree "$FONT_DIR" "$HOME/.local/share/fonts"
    if (( ! DRY_RUN )) && command -v fc-cache >/dev/null 2>&1; then
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
    if (( ! DRY_RUN )); then
        find "$HOME/.local/bin" -maxdepth 1 -type f -exec chmod +x {} +
    fi
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
if (( APPLY_DESKTOP_SETTINGS && ! DRY_RUN )) && command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme 'gruvbox-dark-gtk'
    gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 11'
    gsettings set org.gnome.desktop.interface document-font-name 'JetBrainsMono Nerd Font 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
    echo -e "${GREEN}Done!${NC} GTK settings applied."
elif (( APPLY_DESKTOP_SETTINGS && DRY_RUN )); then
    echo "DRY-RUN: would apply GTK settings through gsettings; no command run."
elif (( ! APPLY_DESKTOP_SETTINGS )); then
    echo "GTK gsettings changes skipped; use --apply-desktop-settings to apply them."
fi

# Note: Wallpaper is applied automatically via autostart.lua once you log into Hyprland.

echo -e "\n${GREEN}Installation Complete!${NC}"
echo -e "${YELLOW}Note:${NC} Brave theme installation is manual; see config/brave/README.md."
echo -e "Please restart Hyprland to apply the changes."
