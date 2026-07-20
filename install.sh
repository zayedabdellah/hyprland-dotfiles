#!/usr/bin/env bash

# Complete, profile-aware installer for the Hyprland rice.
#
# The default invocation is an interactive full installation. Audit and
# dry-run modes are intentionally read-only: they never install packages,
# download upstream tools, change a shell, run gsettings, or deploy files.

set -Eeuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_ROOT/config"
OPTIONAL_MODULES=()
DRY_RUN=0
AUDIT_ONLY=0
SKIP_PACKAGES=0
PACKAGES_ONLY=0
CONFIG_ONLY=0
SET_DEFAULT_SHELL=0
APPLY_DESKTOP_SETTINGS=0
NON_INTERACTIVE=0
PROFILE_NAME=""
PROFILE_EXPLICIT=0
BACKUP_ROOT=""
BACKUP_MANIFEST=""
BACKUP_CREATED=0
INSTALL_CONFIRMATION_DONE=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [OPTIONS]

With no options, run a complete interactive installation: choose a profile,
review the plan, install required packages, deploy the rice, and validate it.

Options:
  --enable-optional MODULE  Enable one optional module (repeatable)
  --audit                   Read-only dependency and configuration audit
  --dry-run                 Read-only preview of installation actions
  --profile PROFILE         Select zayed-laptop or generic
  --packages-only           Install and verify packages, then stop
  --config-only             Skip distro packages and deploy configuration
  --skip-packages           Skip distro packages and deploy configuration
  --set-default-shell       Ask before changing this user's login shell to Fish
  --apply-desktop-settings  Apply GTK settings through gsettings
  --non-interactive         Never prompt; unspecified profile uses generic
  --help                    Show this help

Optional modules:
  retroarch sunshine dolphin-emu suyu goverlay vkBasalt vkSumi
  pavucontrol mimeapps brave
EOF
}

while (($# > 0)); do
    case "$1" in
        --enable-optional)
            [[ $# -ge 2 ]] || { echo "Missing module after --enable-optional" >&2; exit 2; }
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
        --profile)
            [[ $# -ge 2 ]] || { echo "Missing profile after --profile" >&2; exit 2; }
            PROFILE_NAME="$2"
            PROFILE_EXPLICIT=1
            shift 2
            ;;
        --packages-only)
            PACKAGES_ONLY=1
            shift
            ;;
        --config-only)
            CONFIG_ONLY=1
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

if (( PACKAGES_ONLY && CONFIG_ONLY )); then
    echo "--packages-only and --config-only cannot be combined." >&2
    exit 2
fi

case "$PROFILE_NAME" in
    "") ;;
    zayed-laptop|generic) ;;
    *) echo "Invalid profile '$PROFILE_NAME'; choose generic or zayed-laptop." >&2; exit 2 ;;
esac

if (( ! PROFILE_EXPLICIT )) && [[ -n "${DOTFILES_MACHINE_PROFILE:-}" ]]; then
    PROFILE_NAME="$DOTFILES_MACHINE_PROFILE"
    PROFILE_EXPLICIT=1
    case "$PROFILE_NAME" in
        zayed-laptop|generic) ;;
        *) echo "Invalid DOTFILES_MACHINE_PROFILE '$PROFILE_NAME'; choose generic or zayed-laptop." >&2; exit 2 ;;
    esac
fi

for module in "${OPTIONAL_MODULES[@]}"; do
    case "$module" in
        retroarch|sunshine|dolphin-emu|suyu|goverlay|vkBasalt|vkSumi|pavucontrol|mimeapps|brave) ;;
        *) echo "Unknown optional module: $module" >&2; usage >&2; exit 2 ;;
    esac
done

if (( EUID == 0 )) && (( ! DRY_RUN )); then
    echo "Run this installer as the target user, not as root; it uses sudo only for package/system operations." >&2
    exit 1
fi

DISTRO_ID="${DOTFILES_DISTRO_ID:-}"
if [[ -z "$DISTRO_ID" && -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
fi
DISTRO_ID="${DISTRO_ID:-unknown}"

case "$DISTRO_ID" in
    arch|manjaro|gentoo|fedora|nobara|nixos) ;;
    *) echo "Unsupported or unknown distribution '$DISTRO_ID'. No files were changed." >&2; exit 1 ;;
esac

# These are the packages required by the active configuration and its startup
# commands on Arch. The bundled fonts/cursors/themes do not need a package.
ARCH_REQUIRED_PACKAGES=(
    hyprland xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    xorg-xwayland waybar swaync fish kitty rofi hyprlock hypridle awww
    pipewire pipewire-audio pipewire-alsa pipewire-pulse wireplumber
    polkit hyprpolkitagent gtk3 gtk4 qt6ct qt6-wayland qt5-wayland kvantum
    papirus-icon-theme thunar thunar-volman tumbler mpv btop mangohud cava
    grim slurp wl-clipboard brightnessctl playerctl pavucontrol-qt
    networkmanager power-profiles-daemon bluez bluez-utils blueman
    dbus libnotify xorg-xrdb xsettingsd fontconfig iproute2 procps-ng
    coreutils findutils gawk curl unzip xdg-utils xdg-user-dirs
)

# Arch package names for commands actually referenced by the active files.
declare -A ARCH_COMMAND_PACKAGE=(
    [Hyprland]=hyprland
    [hyprland]=hyprland
    [waybar]=waybar
    [swaync]=swaync
    [fish]=fish
    [kitty]=kitty
    [rofi]=rofi
    [hyprlock]=hyprlock
    [hypridle]=hypridle
    [awww]=awww
    [awww-daemon]=awww
    [pipewire]=pipewire
    [wireplumber]=wireplumber
    [wpctl]=pipewire
    [hyprpolkitagent]=hyprpolkitagent
    [qt6ct]=qt6ct
    [kvantummanager]=kvantum
    [thunar]=thunar
    [mpv]=mpv
    [btop]=btop
    [mangohud]=mangohud
    [cava]=cava
    [grim]=grim
    [slurp]=slurp
    [wl-copy]=wl-clipboard
    [brightnessctl]=brightnessctl
    [playerctl]=playerctl
    [wpctl]=pipewire
    [pavucontrol-qt]=pavucontrol-qt
    [nmtui]=networkmanager
    [nmcli]=networkmanager
    [blueman-applet]=blueman
    [powerprofilesctl]=power-profiles-daemon
    [xrdb]=xorg-xrdb
    [notify-send]=libnotify
    [xsettingsd]=xsettingsd
    [fc-cache]=fontconfig
    [ip]=iproute2
    [curl]=curl
    [unzip]=unzip
)

# Optional packages are never installed unless the corresponding module was
# explicitly enabled. AUR use is separately confirmed and requires an existing
# paru or yay; this installer never installs an AUR helper.
declare -A ARCH_OPTIONAL_OFFICIAL=(
    [retroarch]=retroarch
    [sunshine]=sunshine
    [dolphin-emu]=dolphin-emu
    [goverlay]=goverlay
    [vkBasalt]=vkbasalt
    [pavucontrol]=pavucontrol-qt
)
declare -A ARCH_OPTIONAL_AUR=(
    [suyu]=suyu
    [vkSumi]=vksumi
    [brave]=brave-bin
)

# Gentoo mappings remain atoms only. Empty entries deliberately represent
# components for which this repository has not verified a current Gentoo atom.
declare -A GENTOO_COMMAND_PACKAGE=(
    [hyprland]=gui-wm/hyprland
    [waybar]=gui-apps/waybar
    [fish]=app-shells/fish
    [kitty]=app-emulation/kitty
    [rofi]=gui-apps/rofi
    [thunar]=xfce-base/thunar
    [mpv]=media-video/mpv
    [btop]=app-misc/btop
    [mangohud]=games-util/mangohud
    [cava]=media-sound/cava
    [grim]=gui-apps/grim
    [slurp]=gui-apps/slurp
    [wl-copy]=gui-apps/wl-clipboard
    [brightnessctl]=sys-power/brightnessctl
    [playerctl]=media-sound/playerctl
    [pavucontrol-qt]=media-sound/pavucontrol-qt
    [nmtui]=net-misc/networkmanager
    [nmcli]=net-misc/networkmanager
    [blueman-applet]=net-wireless/blueman
    [pipewire]=media-video/pipewire
    [wireplumber]=media-video/wireplumber
    [wpctl]=media-video/pipewire
    [xsettingsd]=x11-misc/xsettingsd
    [qt6ct]=gui-apps/qt6ct
    [kvantummanager]=x11-themes/kvantum
    [xrdb]=x11-apps/xrdb
    [notify-send]=x11-libs/libnotify
    [fc-cache]=media-libs/fontconfig
    [ip]=sys-apps/iproute2
    [curl]=net-misc/curl
    [unzip]=app-arch/unzip
)
declare -A GENTOO_USE_FLAGS=(
    [gui-wm/hyprland]="qtutils"
    [gui-apps/waybar]="network wifi tray mpris pipewire pulseaudio upower"
    [media-video/pipewire]="alsa bluetooth pipewire-alsa pulseaudio sound-server"
    [x11-themes/kvantum]="kde"
)
declare -A GENTOO_OVERLAY_NOTES=(
    [swaync]="No verified main-repository atom in this audit; review the current Gentoo package tree or overlay."
    [hyprlock]="No verified Gentoo atom in this audit; review hyproverlay or build manually."
    [hypridle]="No verified Gentoo atom in this audit; review hyproverlay or build manually."
    [awww]="No verified Gentoo atom in this audit; review hyproverlay or build manually."
    [hyprpolkitagent]="No verified main-repository atom in this audit; review a current overlay or use another approved polkit agent."
)

REQUIRED_COMMANDS=(
    Hyprland waybar swaync fish kitty rofi hyprlock hypridle awww awww-daemon
    pipewire wireplumber wpctl hyprpolkitagent qt6ct kvantummanager thunar mpv btop mangohud cava
    grim slurp wl-copy brightnessctl playerctl pavucontrol-qt nmtui nmcli
    blueman-applet powerprofilesctl xrdb notify-send xsettingsd fc-cache ip
    curl unzip
)

have_command() {
    case "$1" in
        Hyprland) command -v Hyprland >/dev/null 2>&1 || command -v hyprland >/dev/null 2>&1 ;;
        hyprpolkitagent) command -v hyprpolkitagent >/dev/null 2>&1 || \
            [[ -x /usr/lib/hyprpolkitagent/hyprpolkitagent || -x /usr/libexec/hyprpolkitagent ]] ;;
        awww-daemon) command -v awww-daemon >/dev/null 2>&1 ;;
        *) command -v "$1" >/dev/null 2>&1 ;;
    esac
}

check_command() {
    if have_command "$1"; then
        printf '%b[OK]%b %s\n' "$GREEN" "$NC" "$1"
        return 0
    fi
    printf '%b[MISSING]%b %s\n' "$RED" "$NC" "$1"
    return 1
}

package_for_command() {
    local command_name="$1"
    case "$DISTRO_ID" in
        arch|manjaro) printf '%s' "${ARCH_COMMAND_PACKAGE[$command_name]:-}" ;;
        gentoo) printf '%s' "${GENTOO_COMMAND_PACKAGE[$command_name]:-}" ;;
        *) printf '%s' "" ;;
    esac
}

MISSING_COMMANDS=()
UNMAPPED_COMMANDS=()
MISSING_PACKAGES=()

collect_missing() {
    MISSING_COMMANDS=()
    UNMAPPED_COMMANDS=()
    MISSING_PACKAGES=()
    local command_name package
    for command_name in "${REQUIRED_COMMANDS[@]}"; do
        if ! have_command "$command_name"; then
            MISSING_COMMANDS+=("$command_name")
            package="$(package_for_command "$command_name")"
            if [[ -n "$package" ]]; then
                case " ${MISSING_PACKAGES[*]} " in
                    *" $package "*) ;;
                    *) MISSING_PACKAGES+=("$package") ;;
                esac
            else
                UNMAPPED_COMMANDS+=("$command_name")
            fi
        fi
    done
}

detect_zayed_laptop() {
    local monitors="" gpu=""
    if command -v hyprctl >/dev/null 2>&1; then
        monitors="$(hyprctl monitors 2>/dev/null || true)"
    elif command -v wlr-randr >/dev/null 2>&1; then
        monitors="$(wlr-randr 2>/dev/null || true)"
    fi
    if command -v lspci >/dev/null 2>&1; then
        gpu="$(lspci 2>/dev/null | grep -i nvidia || true)"
    fi
    [[ "$monitors" == *eDP-1* && "$monitors" == *2560x1600* && "$monitors" == *165* ]] || return 1
    [[ "$gpu" =~ [Nn][Vv][Ii][Dd][Ii][Aa] ]] || return 1
    return 0
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

    local detected=0 choice default_choice
    if detect_zayed_laptop; then detected=1; fi
    if (( detected )); then
        default_choice=2
    else
        default_choice=1
    fi
    echo
    echo "Machine profile:"
    echo "  1) Generic"
    echo "     Detect monitor, network interface, and safe GPU settings."
    echo "  2) Zayed laptop"
    echo "     Preserve eDP-1, 2560x1600@165, position 0x0, scale 2, wlp3s0, and NVIDIA settings."
    if (( detected )); then
        echo "Detected an exact laptop display/GPU match; option 2 is recommended."
    else
        echo "No exact laptop match was detected; option 1 is recommended."
    fi
    while :; do
        read -r -p "Choose profile [1/2, default ${default_choice}]: " choice
        choice="${choice:-$default_choice}"
        case "$choice" in
            1) PROFILE_NAME="generic"; break ;;
            2) PROFILE_NAME="zayed-laptop"; break ;;
            *) echo "Choose 1 for generic or 2 for zayed-laptop." >&2 ;;
        esac
    done
    echo "Selected machine profile: $PROFILE_NAME"
}

print_list() {
    local item
    for item in "$@"; do printf '  - %s\n' "$item"; done
}

show_summary() {
    echo
    echo "Installation summary"
    echo "  Distribution: $DISTRO_ID"
    echo "  Profile: $PROFILE_NAME"
    if (( AUDIT_ONLY )); then
        echo "  Mode: audit (read-only)"
    elif (( DRY_RUN )); then
        echo "  Mode: dry-run (read-only)"
    elif (( PACKAGES_ONLY )); then
        echo "  Mode: packages-only"
    elif (( CONFIG_ONLY || SKIP_PACKAGES )); then
        echo "  Mode: configuration deployment; distro packages skipped"
    else
        echo "  Mode: complete installation"
    fi
    if [[ "$DISTRO_ID" == arch || "$DISTRO_ID" == manjaro ]]; then
        echo "  Required official Arch packages: ${#ARCH_REQUIRED_PACKAGES[@]}"
        print_list "${ARCH_REQUIRED_PACKAGES[@]}"
    elif [[ "$DISTRO_ID" == gentoo ]]; then
        echo "  Gentoo: only verified atoms will be suggested or installed."
        echo "  Required missing commands: ${#MISSING_COMMANDS[@]}"
        local command_name atom
        for command_name in "${MISSING_COMMANDS[@]}"; do
            atom="$(package_for_command "$command_name")"
            if [[ -n "$atom" ]]; then echo "  - $command_name -> $atom"; else echo "  - $command_name -> UNMAPPED (manual/overlay review required)"; fi
        done
        echo "  Suggested USE flags (not applied):"
        for atom in "${!GENTOO_USE_FLAGS[@]}"; do echo "    $atom USE=\"${GENTOO_USE_FLAGS[$atom]}\""; done
    else
        echo "  Package installation: experimental/documented only for $DISTRO_ID"
    fi
    echo "  User-local upstream component: Oh My Posh ${OH_MY_POSH_VERSION:-v29.31.1}"
    echo "  Shared assets: JetBrains Mono, Bibata cursor, Papirus-Dark dependency, GTK theme, Torii wallpaper"
    echo "  Kvantum: exact local gruvbox-kvantum payload"
    if ((${#OPTIONAL_MODULES[@]})); then
        echo "  Optional modules: ${OPTIONAL_MODULES[*]}"
    else
        echo "  Optional modules: none"
    fi
    if ((${#MISSING_COMMANDS[@]})); then
        echo "  Missing before package installation: ${MISSING_COMMANDS[*]}"
    fi
}

confirm() {
    local prompt="$1" reply
    if (( DRY_RUN || AUDIT_ONLY || NON_INTERACTIVE )); then return 0; fi
    read -r -p "$prompt [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

run_privileged() {
    if (( EUID == 0 )); then
        "$@"
    else
        sudo "$@"
    fi
}

install_arch_packages() {
    (( CONFIG_ONLY || SKIP_PACKAGES || DRY_RUN || AUDIT_ONLY )) && return 0
    if ! command -v pacman >/dev/null 2>&1; then
        echo "Arch package manager pacman is missing; cannot perform a complete installation." >&2
        return 1
    fi
    echo "Installing required official Arch packages..."
    if (( NON_INTERACTIVE )); then
        run_privileged pacman -S --needed --noconfirm "${ARCH_REQUIRED_PACKAGES[@]}"
    else
        run_privileged pacman -S --needed "${ARCH_REQUIRED_PACKAGES[@]}"
    fi
}

install_gentoo_packages() {
    (( CONFIG_ONLY || SKIP_PACKAGES || DRY_RUN || AUDIT_ONLY )) && return 0
    if ((${#UNMAPPED_COMMANDS[@]})); then
        echo "Gentoo has no verified atom mapping for required commands:" >&2
        print_list "${UNMAPPED_COMMANDS[@]}" >&2
        for command_name in "${UNMAPPED_COMMANDS[@]}"; do
            [[ -n "${GENTOO_OVERLAY_NOTES[$command_name]:-}" ]] && echo "  ${GENTOO_OVERLAY_NOTES[$command_name]}" >&2
        done
        echo "Review Portage/overlay choices manually; no configuration will be deployed." >&2
        return 1
    fi
    if ((${#MISSING_PACKAGES[@]} == 0)); then return 0; fi
    echo "Suggested Gentoo atoms:"; print_list "${MISSING_PACKAGES[@]}"
    echo "Suggested USE flags (not applied):"
    for atom in "${!GENTOO_USE_FLAGS[@]}"; do echo "  $atom USE=\"${GENTOO_USE_FLAGS[$atom]}\""; done
    if ! command -v emerge >/dev/null 2>&1; then
        echo "emerge is unavailable; install the listed atoms manually." >&2
        return 1
    fi
    if (( NON_INTERACTIVE )); then
        run_privileged emerge --oneshot --verbose "${MISSING_PACKAGES[@]}"
    else
        run_privileged emerge --ask "${MISSING_PACKAGES[@]}"
    fi
}

install_optional_arch_packages() {
    (( CONFIG_ONLY || SKIP_PACKAGES || DRY_RUN || AUDIT_ONLY )) && return 0
    local module package helper aur_packages=() official_packages=()
    for module in "${OPTIONAL_MODULES[@]}"; do
        if [[ -n "${ARCH_OPTIONAL_OFFICIAL[$module]:-}" ]]; then official_packages+=("${ARCH_OPTIONAL_OFFICIAL[$module]}"); fi
        if [[ -n "${ARCH_OPTIONAL_AUR[$module]:-}" ]]; then aur_packages+=("${ARCH_OPTIONAL_AUR[$module]}"); fi
    done
    if ((${#official_packages[@]})); then
        echo "Installing explicitly enabled optional official packages..."
        if (( NON_INTERACTIVE )); then run_privileged pacman -S --needed --noconfirm "${official_packages[@]}"; else run_privileged pacman -S --needed "${official_packages[@]}"; fi
    fi
    if ((${#aur_packages[@]})); then
        if command -v paru >/dev/null 2>&1; then helper=paru; elif command -v yay >/dev/null 2>&1; then helper=yay; else
            echo "Optional AUR modules requested: ${aur_packages[*]}" >&2
            echo "No paru or yay was found. Install/build these packages manually or install an AUR helper yourself; none will be installed by this script." >&2
            return 1
        fi
        if (( NON_INTERACTIVE )); then
            echo "Non-interactive mode will not use an AUR helper without an explicit interactive approval." >&2
            return 1
        fi
        if ! confirm "Use existing $helper to install optional AUR packages ${aur_packages[*]}?"; then
            echo "Optional AUR installation declined." >&2
            return 1
        fi
        "$helper" -S --needed "${aur_packages[@]}"
    fi
}

verify_required_commands() {
    local failed=0 command_name
    echo "Verifying mandatory executables..."
    for command_name in "${REQUIRED_COMMANDS[@]}"; do
        if ! check_command "$command_name"; then failed=1; fi
    done
    if [[ ! -f /usr/share/wayland-sessions/hyprland.desktop && ! -f /usr/share/wayland-sessions/hyprland-uwsm.desktop ]]; then
        echo "[WARNING] Hyprland session file was not found under /usr/share/wayland-sessions." >&2
    fi
    if (( failed )); then
        echo "Mandatory components are still missing; refusing to deploy configuration." >&2
        return 1
    fi
}

install_oh_my_posh() {
    local target="$HOME/.local/bin/oh-my-posh" version="${OH_MY_POSH_VERSION:-v29.31.1}"
    if [[ -x "$target" ]]; then
        echo "[OK] Oh My Posh: $target"
        return 0
    fi
    if (( AUDIT_ONLY || DRY_RUN )); then
        echo "DRY-RUN: would install Oh My Posh $version to $target using the official upstream installer; no download performed."
        return 0
    fi
    if [[ "$DISTRO_ID" == nixos ]]; then
        echo "NixOS requires a declarative Home Manager Oh My Posh option; no download was attempted." >&2
        return 1
    fi
    for helper in curl unzip; do
        have_command "$helper" || { echo "Oh My Posh requires $helper." >&2; return 1; }
    done
    mkdir -p "$(dirname -- "$target")"
    echo "Installing Oh My Posh $version to $target..."
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin" -v "$version"
    [[ -x "$target" ]] || { echo "Oh My Posh installation did not create $target." >&2; return 1; }
}

configure_fish_shell() {
    local fish_path reply prompt=0
    if (( SET_DEFAULT_SHELL )); then prompt=1; fi
    if (( ! NON_INTERACTIVE && ! AUDIT_ONLY && ! DRY_RUN && ! PACKAGES_ONLY && ! CONFIG_ONLY && ! SKIP_PACKAGES )); then prompt=1; fi
    if (( ! prompt )); then
        if (( SET_DEFAULT_SHELL && (AUDIT_ONLY || DRY_RUN) )); then
            fish_path="$(command -v fish || true)"
            echo "DRY-RUN: would validate Fish and ask before changing only this user's login shell; no change performed."
        fi
        return 0
    fi
    fish_path="$(command -v fish || true)"
    [[ -n "$fish_path" ]] || { echo "Fish is missing; login shell unchanged." >&2; return 1; }
    if (( AUDIT_ONLY || DRY_RUN )); then
        echo "DRY-RUN: would verify $fish_path in /etc/shells and ask before changing only $USER's login shell; no change performed."
        return 0
    fi
    if (( NON_INTERACTIVE )); then
        echo "Non-interactive mode leaves the login shell unchanged. Use an interactive run with --set-default-shell." >&2
        return 0
    fi
    if (( EUID == 0 )); then echo "Refusing to change root's shell." >&2; return 1; fi
    if ! grep -Fxq "$fish_path" /etc/shells 2>/dev/null; then
        read -r -p "Add $fish_path to /etc/shells with sudo? [Y/n] " reply
        if [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]; then printf '%s\n' "$fish_path" | run_privileged tee -a /etc/shells >/dev/null; else echo "Login shell unchanged."; return 0; fi
    fi
    read -r -p "Make Fish the default shell for $USER? [Y/n] " reply
    if [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]; then chsh -s "$fish_path"; else echo "Login shell unchanged."; fi
}

backup_existing() {
    local destination="$1" relative backup
    [[ -e "$destination" || -L "$destination" ]] || return 0
    (( DRY_RUN || AUDIT_ONLY )) && return 0
    if [[ -z "$BACKUP_ROOT" ]]; then
        local backup_base="$HOME/.local/state/dotfiles/backups/$(date +%Y%m%d-%H%M%S)"
        BACKUP_ROOT="$backup_base"
        local backup_suffix=0
        while [[ -e "$BACKUP_ROOT" ]]; do
            backup_suffix=$((backup_suffix + 1))
            BACKUP_ROOT="${backup_base}-${backup_suffix}"
        done
        BACKUP_MANIFEST="$BACKUP_ROOT/manifest.tsv"
        mkdir -p "$BACKUP_ROOT"
        printf 'source\tbackup\ttimestamp\n' > "$BACKUP_MANIFEST"
    fi
    relative="${destination#"$HOME"/}"
    backup="$BACKUP_ROOT/$relative"
    mkdir -p "$(dirname -- "$backup")"
    cp -a "$destination" "$backup"
    printf '%s\t%s\t%s\n' "$destination" "$backup" "$(date --iso-8601=seconds)" >> "$BACKUP_MANIFEST"
    BACKUP_CREATED=1
}

copy_file() {
    local source="$1" destination="$2"
    [[ -e "$source" || -L "$source" ]] || { echo "Missing repository file: $source" >&2; return 1; }
    if (( DRY_RUN || AUDIT_ONLY )); then echo "[DRY-RUN] $source -> $destination"; return 0; fi
    if [[ -f "$source" && -f "$destination" ]] && cmp -s "$source" "$destination"; then return 0; fi
    backup_existing "$destination"
    mkdir -p "$(dirname -- "$destination")"
    cp -a "$source" "$destination"
}

copy_tree() {
    local source="$1" destination="$2" item relative target
    [[ -d "$source" ]] || { echo "Missing repository directory: $source" >&2; return 1; }
    if (( DRY_RUN || AUDIT_ONLY )); then echo "[DRY-RUN] directory $source -> $destination"; return 0; fi
    while IFS= read -r -d '' item; do
        relative="${item#"$source"/}"
        target="$destination/$relative"
        if [[ -d "$item" && ! -L "$item" ]]; then
            mkdir -p "$target"
        else
            copy_file "$item" "$target"
        fi
    done < <(find "$source" -mindepth 1 -print0)
}

render_selected_waybar_config() {
    local source="$CONFIG_DIR/waybar/config.jsonc.template" destination="$HOME/.config/waybar/config.jsonc" temporary
    temporary="$(mktemp)"
    trap 'rm -f "$temporary"' RETURN
    if [[ "$PROFILE_NAME" == zayed-laptop ]]; then
        sed 's#__DOTFILES_NETWORK_INTERFACE__#wlp3s0#g' "$source" > "$temporary"
    else
        sed '/"interface": "__DOTFILES_NETWORK_INTERFACE__"/d' "$source" > "$temporary"
    fi
    copy_file "$temporary" "$destination"
    rm -f "$temporary"
    trap - RETURN
}

persist_profile_selection() {
    local target="$HOME/.config/hypr/machine.local.lua"
    if (( DRY_RUN || AUDIT_ONLY )); then echo "[DRY-RUN] select $PROFILE_NAME in $target"; return 0; fi
    if [[ -e "$target" ]]; then
        if grep -q '^-- Generated by dotfiles installer' "$target"; then
            if grep -q "profile = \"$PROFILE_NAME\"" "$target"; then return 0; fi
            backup_existing "$target"
            printf '%s\n' '-- Generated by dotfiles installer; local and ignored by Git.' "return { profile = \"$PROFILE_NAME\" }" > "$target"
        else
            echo "Warning: preserving user-managed $target; verify it selects '$PROFILE_NAME'." >&2
        fi
        return 0
    fi
    mkdir -p "$(dirname -- "$target")"
    printf '%s\n' '-- Generated by dotfiles installer; local and ignored by Git.' "return { profile = \"$PROFILE_NAME\" }" > "$target"
}

deploy_configuration() {
    (( PACKAGES_ONLY )) && return 0
    echo "Deploying configuration and assets..."
    mkdir -p "$HOME/.config" "$HOME/.themes" "$HOME/.local/bin" \
        "$HOME/.local/share/icons" "$HOME/.local/share/fonts" "$HOME/.local/share/applications"
    persist_profile_selection

    local component
    local core=(Kvantum MangoHud Thunar btop cava fish gtk-3.0 gtk-4.0 hypr kitty mpv qt6ct rofi swaync waybar xsettingsd)
    for component in "${core[@]}"; do
        [[ -d "$CONFIG_DIR/$component" ]] && copy_tree "$CONFIG_DIR/$component" "$HOME/.config/$component"
    done
    render_selected_waybar_config
    copy_file "$CONFIG_DIR/kdeglobals" "$HOME/.config/kdeglobals"

    # GTK and Oh My Posh are user themes. Do not copy repository documentation
    # into the live theme roots.
    copy_tree "$SCRIPT_ROOT/themes/gruvbox-dark-gtk" "$HOME/.themes/gruvbox-dark-gtk"
    copy_file "$SCRIPT_ROOT/themes/oh-my-posh/torii-zayed.omp.json" "$HOME/.themes/torii-zayed.omp.json"

    # This is the exact active local Kvantum theme payload. It is intentionally
    # copied only because the owner approved local repository testing.
    copy_tree "$SCRIPT_ROOT/themes/kvantum/gruvbox-kvantum" "$HOME/.config/Kvantum/gruvbox-kvantum"
    copy_tree "$SCRIPT_ROOT/themes/kvantum/gruvbox-kvantum" "$HOME/.themes/gruvbox-kvantum"

    copy_tree "$SCRIPT_ROOT/fonts/fonts/ttf" "$HOME/.local/share/fonts"
    copy_file "$SCRIPT_ROOT/fonts/OFL.txt" "$HOME/.local/share/fonts/JetBrainsMono-OFL.txt"
    copy_tree "$SCRIPT_ROOT/icons" "$HOME/.local/share/icons"
    copy_tree "$SCRIPT_ROOT/scripts" "$HOME/.local/bin"

    local module
    for module in "${OPTIONAL_MODULES[@]}"; do
        echo "Deploying optional module: $module"
        case "$module" in
            retroarch) copy_file "$CONFIG_DIR/optional/retroarch/appearance.cfg" "$HOME/.config/retroarch/appearance.cfg" ;;
            sunshine) copy_file "$CONFIG_DIR/optional/sunshine/apps.json" "$HOME/.config/sunshine/apps.json" ;;
            dolphin-emu)
                copy_file "$CONFIG_DIR/optional/dolphin-emu/appearance.ini" "$HOME/.config/dolphin-emu/appearance.ini"
                copy_file "$CONFIG_DIR/local/share/applications/dolphin-emu.desktop" "$HOME/.local/share/applications/dolphin-emu.desktop"
                ;;
            suyu) copy_file "$CONFIG_DIR/optional/suyu/appearance.ini" "$HOME/.config/suyu/appearance.ini" ;;
            goverlay) copy_file "$CONFIG_DIR/optional/goverlay/goverlay.conf" "$HOME/.config/goverlay/goverlay.conf" ;;
            vkBasalt) copy_file "$CONFIG_DIR/optional/vkBasalt/vkBasalt.conf" "$HOME/.config/vkBasalt/vkBasalt.conf" ;;
            vkSumi) copy_file "$CONFIG_DIR/optional/vkSumi/vkSumi.conf" "$HOME/.config/vkSumi/vkSumi.conf" ;;
            pavucontrol) echo "No reusable Pavucontrol preference file was found; package only." ;;
            mimeapps) copy_file "$CONFIG_DIR/optional/mimeapps.list" "$HOME/.config/mimeapps.list" ;;
            brave)
                copy_tree "$CONFIG_DIR/brave" "$HOME/.local/share/dotfiles/brave-theme"
                echo "Brave theme assets staged at ~/.local/share/dotfiles/brave-theme; load the unpacked theme manually. No browser profile was copied."
                ;;
        esac
    done
    if command -v fc-cache >/dev/null 2>&1; then fc-cache -f; fi
}

apply_desktop_settings() {
    if (( APPLY_DESKTOP_SETTINGS && DRY_RUN )); then
        echo "DRY-RUN: would ask gsettings to apply GTK theme/font settings; no command run."
    elif (( APPLY_DESKTOP_SETTINGS )); then
        command -v gsettings >/dev/null 2>&1 || { echo "gsettings is unavailable; desktop settings skipped." >&2; return 0; }
        gsettings set org.gnome.desktop.interface gtk-theme 'gruvbox-dark-gtk'
        gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 11'
        gsettings set org.gnome.desktop.interface document-font-name 'JetBrainsMono Nerd Font 11'
        gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
    fi
}

validate_deployment() {
    (( PACKAGES_ONLY )) && return 0
    local failed=0 path
    echo "Validating deployed configuration..."
    for path in \
        "$HOME/.config/hypr/hyprland.lua" \
        "$HOME/.config/hypr/profiles/generic.lua" \
        "$HOME/.config/hypr/profiles/zayed-laptop.lua" \
        "$HOME/.config/hypr/wallpapers/torii.jpg" \
        "$HOME/.config/waybar/config.jsonc" \
        "$HOME/.config/waybar/config.jsonc.template" \
        "$HOME/.config/btop/themes/gruvbox_dark_v2.theme" \
        "$HOME/.themes/torii-zayed.omp.json" \
        "$HOME/.config/Kvantum/gruvbox-kvantum/gruvbox-kvantum.kvconfig" \
        "$HOME/.config/Kvantum/gruvbox-kvantum/gruvbox-kvantum.svg"; do
        [[ -e "$path" ]] || { echo "[MISSING] $path" >&2; failed=1; }
    done
    grep -q 'persistent-workspaces.*\[1, 2, 3, 4, 5\]' "$HOME/.config/waybar/config.jsonc.template" || { echo "[MISSING] Waybar persistent workspaces 1-5" >&2; failed=1; }
    grep -q '^color_theme = "gruvbox_dark_v2"' "$HOME/.config/btop/btop.conf" || { echo "[MISSING] btop Gruvbox theme selection" >&2; failed=1; }
    grep -q '^theme=gruvbox-kvantum' "$HOME/.config/Kvantum/kvantum.kvconfig" || { echo "[MISSING] Kvantum selector" >&2; failed=1; }
    if command -v fish >/dev/null 2>&1; then fish -n "$HOME/.config/fish/config.fish" || failed=1; fi
    if command -v hyprland >/dev/null 2>&1; then
        if ! HOME="$HOME" hyprland --verify-config >/dev/null 2>&1; then echo "[FAILED] Hyprland configuration verification" >&2; failed=1; else echo "[OK] Hyprland configuration"; fi
    fi
    if (( failed )); then return 1; fi
}

show_warnings() {
    echo
    echo "Remaining warnings"
    echo "  - Oranchelo is not bundled; Rofi uses it when installed and falls back to Papirus-Dark."
    echo "  - Brave is optional/AUR and no browser profile is copied. Use --enable-optional brave explicitly."
    echo "  - Fedora package installation is experimental; NixOS requires native Home Manager/NixOS modules."
    echo "  - Kvantum payload source is a locally approved copy by Sourav Gope; redistribution licensing still needs review before public release."
    if [[ "$DISTRO_ID" == gentoo ]]; then echo "  - Gentoo requires manual review for unmapped Hypr ecosystem atoms and USE flags."; fi
    if (( BACKUP_CREATED )); then echo "  - Replaced files were backed up under $BACKUP_ROOT; manifest: $BACKUP_MANIFEST"; fi
}

resolve_profile
collect_missing
show_summary

if (( AUDIT_ONLY )); then
    install_oh_my_posh
    configure_fish_shell
    apply_desktop_settings
    echo "Audit complete: no packages, downloads, shell changes, gsettings, or file deployment were performed."
    exit 0
fi
if (( DRY_RUN )); then
    install_oh_my_posh
    configure_fish_shell
    apply_desktop_settings
    echo "Dry-run complete: no packages, downloads, shell changes, gsettings, or file deployment were performed."
    exit 0
fi

if (( ! CONFIG_ONLY && ! SKIP_PACKAGES )); then
    confirm "Proceed with the complete package installation?" || { echo "Installation cancelled before changes."; exit 0; }
    INSTALL_CONFIRMATION_DONE=1
    case "$DISTRO_ID" in
        arch|manjaro) install_arch_packages ;;
        gentoo) install_gentoo_packages ;;
        fedora|nobara) echo "Fedora package installation is experimental and not implemented; refusing to deploy a partial package set." >&2; exit 1 ;;
        nixos) echo "NixOS requires declarative Home Manager/NixOS modules; refusing to use an imperative package installer." >&2; exit 1 ;;
    esac
    if [[ "$DISTRO_ID" == arch || "$DISTRO_ID" == manjaro ]]; then install_optional_arch_packages; fi
else
    if ((${#MISSING_COMMANDS[@]})); then
        echo "Required commands are missing while package installation is disabled: ${MISSING_COMMANDS[*]}" >&2
        echo "Use a normal full installation before deploying configuration." >&2
        exit 1
    fi
fi

if [[ "$DISTRO_ID" == arch || "$DISTRO_ID" == manjaro ]]; then
    collect_missing
    verify_required_commands
fi

if (( PACKAGES_ONLY )); then
    configure_fish_shell
    echo "Package installation and verification complete; configuration was not deployed."
    exit 0
fi

install_oh_my_posh

if (( ! INSTALL_CONFIRMATION_DONE )) && ! confirm "Deploy the selected profile and configuration now?"; then
    echo "Package changes completed; configuration deployment cancelled." >&2
    exit 0
fi
deploy_configuration
apply_desktop_settings
configure_fish_shell
validate_deployment

echo
echo -e "${GREEN}Complete rice installation finished.${NC}"
echo "Selected profile: $PROFILE_NAME"
echo "Torii is configured for both profiles and will be loaded by the Hyprland autostart wallpaper script."
echo "Start Hyprland from the installed session entry, or reboot and select Hyprland at the login screen."
show_warnings
