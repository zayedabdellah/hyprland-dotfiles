#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-safety-home.XXXXXX")"
MOCK_BIN="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-safety-bin.XXXXXX")"
LOG_FILE="$TEST_HOME/write-commands.log"
trap 'rm -rf "$TEST_HOME" "$MOCK_BIN"' EXIT

for command_name in hyprland waybar kitty fish rofi swaync hyprlock thunar grim slurp \
    wl-copy brightnessctl playerctl nwg-look kvantummanager qt6ct qt5ct \
    pavucontrol-qt nmtui btop hyprpolkitagent polkit-kde-agent fc-cache; do
    ln -s /bin/true "$MOCK_BIN/$command_name"
done

for command_name in chsh sudo curl gsettings pacman emerge dnf dnf5; do
    script="$MOCK_BIN/$command_name"
    printf '%s\n' '#!/bin/sh' \
        'printf "%s\\n" "$0 $*" >> "$DOTFILES_TEST_LOG"' \
        'exit 99' > "$script"
    chmod +x "$script"
done

run_read_only_case() {
    local mode="$1"
    shift
    : > "$LOG_FILE"
    HOME="$TEST_HOME" \
    PATH="$MOCK_BIN:/usr/bin:/bin" \
    DOTFILES_TEST_LOG="$LOG_FILE" \
    bash "$ROOT/install.sh" --skip-packages --profile generic "$mode" \
        --set-default-shell --apply-desktop-settings "$@" >/dev/null
    [[ ! -s "$LOG_FILE" ]] || {
        echo "$mode invoked a write-capable command:" >&2
        cat "$LOG_FILE" >&2
        return 1
    }
    [[ ! -e "$TEST_HOME/.config/hypr/machine.local.lua" ]]
}

run_read_only_case --dry-run --enable-optional dolphin-emu
run_read_only_case --audit
echo "installer audit/dry-run safety: OK"
