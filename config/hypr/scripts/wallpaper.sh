#!/bin/bash
set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPER="$CONFIG_HOME/hypr/wallpapers/torii.jpg"
PROFILE="${DOTFILES_MACHINE_PROFILE:-generic}"

if [[ "$PROFILE" != "zayed-laptop" ]]; then
    exit 0
fi

if [[ ! -r "$WALLPAPER" ]]; then
    echo "dotfiles: Torii wallpaper not found; retaining the current wallpaper" >&2
    exit 0
fi

if ! command -v awww-daemon >/dev/null 2>&1 || ! command -v awww >/dev/null 2>&1; then
    echo "dotfiles: awww is unavailable; wallpaper was not changed" >&2
    exit 0
fi

if ! awww query >/dev/null 2>&1; then
    awww-daemon --no-cache >/dev/null 2>&1 &
    for _ in {1..30}; do
        if awww query >/dev/null 2>&1; then
            break
        fi
        sleep 0.1
    done
fi

if ! awww query >/dev/null 2>&1; then
    echo "dotfiles: awww daemon did not become ready; wallpaper was not changed" >&2
    exit 0
fi

awww img --transition-type none "$WALLPAPER" || {
    echo "dotfiles: failed to load Torii wallpaper" >&2
    exit 0
}
