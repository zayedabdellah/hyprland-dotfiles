
#!/bin/bash

# Function to check if a command exists
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# Function to prompt user for manual installation
manual_install_prompt () {
  echo "--------------------------------------------------"
  echo "WARNING: '$1' was not detected on your system."
  echo "This component is required for the Hyprland configuration to function correctly."
  echo "Please install it manually using your distribution's package manager or by compiling from source."
  echo "Refer to your distribution's documentation for installation instructions."
  echo "--------------------------------------------------"
  read -p "Do you want to continue without '$1'? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Exiting installation. Please install '$1' and run the script again."
    exit 1
  fi
}

# Detect Linux distribution
DISTRO="$(grep -E '^ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')"
VERSION_ID="$(grep -E '^VERSION_ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')"

echo "Detected Distribution: $DISTRO (Version: $VERSION_ID)"

# Define dependencies and their package names for common distributions
declare -A PKG_NAMES
PKG_NAMES[hyprland_arch]="hyprland"
PKG_NAMES[hyprland_debian]="hyprland"
PKG_NAMES[hyprland_ubuntu]="hyprland"
PKG_NAMES[hyprland_fedora]="hyprland"
PKG_NAMES[hyprland_gentoo]="gui-wm/hyprland"

PKG_NAMES[waybar_arch]="waybar"
PKG_NAMES[waybar_debian]="waybar"
PKG_NAMES[waybar_ubuntu]="waybar"
PKG_NAMES[waybar_fedora]="waybar"
PKG_NAMES[waybar_gentoo]="gui-apps/waybar"

PKG_NAMES[kitty_arch]="kitty"
PKG_NAMES[kitty_debian]="kitty"
PKG_NAMES[kitty_ubuntu]="kitty"
PKG_NAMES[kitty_fedora]="kitty"
PKG_NAMES[kitty_gentoo]="x11-terms/kitty"

PKG_NAMES[thunar_arch]="thunar"
PKG_NAMES[thunar_debian]="thunar"
PKG_NAMES[thunar_ubuntu]="thunar"
PKG_NAMES[thunar_fedora]="thunar"
PKG_NAMES[thunar_gentoo]="x11-misc/thunar"

PKG_NAMES[rofi_arch]="rofi"
PKG_NAMES[rofi_debian]="rofi"
PKG_NAMES[rofi_ubuntu]="rofi"
PKG_NAMES[rofi_fedora]="rofi"
PKG_NAMES[rofi_gentoo]="x11-misc/rofi"

PKG_NAMES[brave-browser_arch]="brave-browser"
PKG_NAMES[brave-browser_debian]="brave-browser"
PKG_NAMES[brave-browser_ubuntu]="brave-browser"
PKG_NAMES[brave-browser_fedora]="brave-browser"
PKG_NAMES[brave-browser_gentoo]="www-client/brave-browser"

PKG_NAMES[hyprshutdown_arch]="hyprshutdown"
PKG_NAMES[hyprshutdown_debian]="hyprshutdown"
PKG_NAMES[hyprshutdown_ubuntu]="hyprshutdown"
PKG_NAMES[hyprshutdown_fedora]="hyprshutdown"
PKG_NAMES[hyprshutdown_gentoo]="gui-apps/hyprshutdown"

PKG_NAMES[hyprlock_arch]="hyprlock"
PKG_NAMES[hyprlock_debian]="hyprlock"
PKG_NAMES[hyprlock_ubuntu]="hyprlock"
PKG_NAMES[hyprlock_fedora]="hyprlock"
PKG_NAMES[hyprlock_gentoo]="gui-apps/hyprlock"

PKG_NAMES[grim_arch]="grim"
PKG_NAMES[grim_debian]="grim"
PKG_NAMES[grim_ubuntu]="grim"
PKG_NAMES[grim_fedora]="grim"
PKG_NAMES[grim_gentoo]="gui-apps/grim"

PKG_NAMES[slurp_arch]="slurp"
PKG_NAMES[slurp_debian]="slurp"
PKG_NAMES[slurp_ubuntu]="slurp"
PKG_NAMES[slurp_fedora]="slurp"
PKG_NAMES[slurp_gentoo]="gui-apps/slurp"

PKG_NAMES[wl-clipboard_arch]="wl-clipboard"
PKG_NAMES[wl-clipboard_debian]="wl-clipboard"
PKG_NAMES[wl-clipboard_ubuntu]="wl-clipboard"
PKG_NAMES[wl-clipboard_fedora]="wl-clipboard"
PKG_NAMES[wl-clipboard_gentoo]="app-admin/wl-clipboard"

PKG_NAMES[pipewire_arch]="pipewire"
PKG_NAMES[pipewire_debian]="pipewire"
PKG_NAMES[pipewire_ubuntu]="pipewire"
PKG_NAMES[pipewire_fedora]="pipewire"
PKG_NAMES[pipewire_gentoo]="media-libs/pipewire"

PKG_NAMES[brightnessctl_arch]="brightnessctl"
PKG_NAMES[brightnessctl_debian]="brightnessctl"
PKG_NAMES[brightnessctl_ubuntu]="brightnessctl"
PKG_NAMES[brightnessctl_fedora]="brightnessctl"
PKG_NAMES[brightnessctl_gentoo]="app-misc/brightnessctl"

PKG_NAMES[playerctl_arch]="playerctl"
PKG_NAMES[playerctl_debian]="playerctl"
PKG_NAMES[playerctl_ubuntu]="playerctl"
PKG_NAMES[playerctl_fedora]="playerctl"
PKG_NAMES[playerctl_gentoo]="media-sound/playerctl"

PKG_NAMES[swaync_arch]="swaync"
PKG_NAMES[swaync_debian]="swaync"
PKG_NAMES[swaync_ubuntu]="swaync"
PKG_NAMES[swaync_fedora]="swaync"
PKG_NAMES[swaync_gentoo]="gui-apps/swaync"

PKG_NAMES[awww-daemon_arch]="awww"
PKG_NAMES[awww-daemon_debian]="awww"
PKG_NAMES[awww-daemon_ubuntu]="awww"
PKG_NAMES[awww-daemon_fedora]="awww"
PKG_NAMES[awww-daemon_gentoo]="gui-apps/awww"

PKG_NAMES[hyprpolkitagent_arch]="hyprpolkitagent"
PKG_NAMES[hyprpolkitagent_debian]="hyprpolkitagent"
PKG_NAMES[hyprpolkitagent_ubuntu]="hyprpolkitagent"
PKG_NAMES[hyprpolkitagent_fedora]="hyprpolkitagent"
PKG_NAMES[hyprpolkitagent_gentoo]="gui-apps/hyprpolkitagent"

PKG_NAMES[nwg-look_arch]="nwg-look"
PKG_NAMES[nwg-look_debian]="nwg-look"
PKG_NAMES[nwg-look_ubuntu]="nwg-look"
PKG_NAMES[nwg-look_fedora]="nwg-look"
PKG_NAMES[nwg-look_gentoo]="gui-apps/nwg-look"

PKG_NAMES[kvantum_arch]="kvantum"
PKG_NAMES[kvantum_debian]="qt5-style-kvantum"
PKG_NAMES[kvantum_ubuntu]="qt5-style-kvantum"
PKG_NAMES[kvantum_fedora]="kvantum"
PKG_NAMES[kvantum_gentoo]="x11-themes/kvantum"

PKG_NAMES[qt6ct_arch]="qt6ct"
PKG_NAMES[qt6ct_debian]="qt6ct"
PKG_NAMES[qt6ct_ubuntu]="qt6ct"
PKG_NAMES[qt6ct_fedora]="qt6ct"
PKG_NAMES[qt6ct_gentoo]="dev-qt/qt6ct"

PKG_NAMES[fish_arch]="fish"
PKG_NAMES[fish_debian]="fish"
PKG_NAMES[fish_ubuntu]="fish"
PKG_NAMES[fish_fedora]="fish"
PKG_NAMES[fish_gentoo]="app-shells/fish"

# List of core dependencies to check
CORE_DEPS=("hyprland" "waybar" "kitty" "thunar" "rofi" "brave-browser" "hyprshutdown" "hyprlock" "grim" "slurp" "wl-copy" "pipewire" "brightnessctl" "playerctl" "swaync" "awww-daemon" "hyprpolkitagent" "nwg-look" "kvantum" "qt6ct" "fish")

INSTALL_COMMANDS=()

for dep in "${CORE_DEPS[@]}"; do
  if ! command_exists "$dep"; then
    echo "Checking for $dep... Not found."
    PKG_NAME="${PKG_NAMES[${dep}_${DISTRO}]}"
    if [[ -n "$PKG_NAME" ]]; then
      INSTALL_COMMANDS+=("$PKG_NAME")
    else
      manual_install_prompt "$dep"
    fi
  else
    echo "Checking for $dep... Found."
  fi
done

if [[ ${#INSTALL_COMMANDS[@]} -gt 0 ]]; then
  echo "--------------------------------------------------"
  echo "Some required components are missing. Here are the suggested installation commands for your distribution:"
  echo "--------------------------------------------------"
  case "$DISTRO" in
    "arch")
      echo "sudo pacman -S ${INSTALL_COMMANDS[@]}"
      ;;
    "debian")
      echo "sudo apt install ${INSTALL_COMMANDS[@]}"
      ;;
    "ubuntu")
      echo "sudo apt install ${INSTALL_COMMANDS[@]}"
      ;;
    "fedora")
      echo "sudo dnf install ${INSTALL_COMMANDS[@]}"
      ;;
    "gentoo")
      echo "# For Gentoo, ensure hyproverlay is enabled and then run:"
      echo "# eselect repository enable hyproverlay"
      echo "# emaint sync -r hyproverlay"
      echo "# echo \"*/* : :hyproverlay\" | sudo tee -a /etc/portage/package.accept_keywords/hyproverlay"
      echo "sudo emerge --ask ${INSTALL_COMMANDS[@]}"
      ;;
    *)
      echo "Could not provide specific installation commands for your distribution ($DISTRO)."
      echo "Please install the following packages manually: ${INSTALL_COMMANDS[@]}"
      ;;
  esac
  echo "--------------------------------------------------"
  read -p "Do you want to continue with configuration copying despite missing components? (y/N): " confirm_copy
  if [[ ! "$confirm_copy" =~ ^[yY]$ ]]; then
    echo "Exiting installation."
    exit 1
  fi
fi

echo "Creating ~/.config directory if it doesn't exist..."
mkdir -p "$HOME/.config"

echo "Copying Hyprland configurations..."
cp -r "$(dirname "$0")"/config/hypr "$HOME/.config/"

echo "Copying Waybar configurations..."
cp -r "$(dirname "$0")"/config/waybar "$HOME/.config/"

echo "Copying Kitty configurations..."
cp -r "$(dirname "$0")"/config/kitty "$HOME/.config/"

echo "Copying Fish configurations..."
cp -r "$(dirname "$0")"/config/fish "$HOME/.config/"

# The user mentioned themes.zip will be sent later, so add a placeholder for now.
echo "Creating ~/.themes directory if it doesn't exist..."
mkdir -p "$HOME/.themes"

echo "Copying themes..."
cp -r "$(dirname "$0")"/themes/* "$HOME/.themes/"
echo "Theme files have been copied to ~/.themes."

echo "Installing JetBrains Mono fonts..."
mkdir -p "$HOME/.local/share/fonts"
cp -r "$(dirname "$0")"/fonts/* "$HOME/.local/share/fonts/"
if command_exists fc-cache; then
  fc-cache -f
  echo "Font cache updated."
fi

echo "Applying GTK theme using gsettings..."
if command_exists gsettings; then
  gsettings set org.gnome.desktop.interface gtk-theme "gruvbox-dark-gtk"
  echo "GTK theme set to gruvbox-dark-gtk."
else
  echo "gsettings not found. Please set your GTK theme to 'gruvbox-dark-gtk' manually using nwg-look."
fi

echo "--------------------------------------------------"
echo "Final Setup Instructions:"
echo "1. Open 'nwg-look' to verify your GTK theme and icons."
echo "2. Open 'Kvantum Manager', select 'Change/Delete Theme', and choose 'gruvbox-kvantum'."
echo "3. Open 'qt6ct' and ensure the style is set to 'kvantum'."
echo "--------------------------------------------------"

echo "Installation script finished. Please restart Hyprland to apply changes."
