#!/bin/bash

set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_FILE="$CONFIG_HOME/hypr/hyprlock.conf"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
RUNTIME_CONFIG="$RUNTIME_DIR/dotfiles-hyprlock-${UID:-$(id -u)}.conf"
WALLPAPER="$CONFIG_HOME/hypr/wallpapers/torii.jpg"

if [[ ! -r "$CONFIG_FILE" ]]; then
    echo "dotfiles: missing Hyprlock configuration: $CONFIG_FILE" >&2
    exec hyprlock "$@"
fi

if [[ "${DOTFILES_MACHINE_PROFILE:-generic}" == "zayed-laptop" && -f "$WALLPAPER" ]]; then
    # The selected image is only read by this wrapper and is never replaced
    # or removed by it.
    wallpaper_path="$WALLPAPER"
else
    wallpaper_path="screenshot"
    if [[ "${DOTFILES_MACHINE_PROFILE:-generic}" == "zayed-laptop" ]]; then
        echo "dotfiles: Torii wallpaper not found; using Hyprlock screenshot fallback" >&2
    fi
fi

escaped_path=${wallpaper_path//\\/\\\\}
escaped_path=${escaped_path//&/\\&}
escaped_path=${escaped_path//#/\\#}

umask 077
sed "s#^[[:space:]]*path = .*#    path = $escaped_path#" "$CONFIG_FILE" > "$RUNTIME_CONFIG"
exec hyprlock --config "$RUNTIME_CONFIG" "$@"
