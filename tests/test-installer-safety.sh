#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-installer-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

make_mock_bin() {
    local bin="$1" command_name
    mkdir -p "$bin"
    for command_name in Hyprland hyprland waybar swaync fish kitty rofi hyprlock hypridle \
        awww awww-daemon pipewire wireplumber wpctl hyprpolkitagent thunar mpv btop \
        mangohud cava grim slurp wl-copy brightnessctl playerctl pavucontrol-qt nmtui \
        nmcli blueman-applet powerprofilesctl xrdb notify-send xsettingsd fc-cache ip \
        curl unzip pacman; do
        ln -s /bin/true "$bin/$command_name"
    done
    cat > "$bin/sudo" <<'EOF'
#!/bin/sh
printf '%s\n' "sudo $*" >> "$DOTFILES_TEST_LOG"
exec "$@"
EOF
    chmod +x "$bin/sudo"
}

make_mock_curl() {
    local bin="$1"
    rm -f "$bin/curl"
    cat > "$bin/curl" <<'EOF'
#!/bin/sh
if [ "${DOTFILES_CURL_FAIL:-0}" = 1 ]; then
    printf '%s\n' "curl $*" >> "$DOTFILES_TEST_LOG"
    exit 77
fi
cat <<'INSTALLER'
#!/bin/bash
destination="$HOME/.local/bin"
while (($# > 0)); do
    if [[ "$1" == "-d" ]]; then destination="$2"; shift 2; else shift; fi
done
mkdir -p "$destination"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$destination/oh-my-posh"
chmod +x "$destination/oh-my-posh"
INSTALLER
EOF
    chmod +x "$bin/curl"
}

make_mock_pacman() {
    local bin="$1"
    rm -f "$bin/pacman"
    cat > "$bin/pacman" <<'EOF'
#!/bin/sh
printf '%s\n' "pacman $*" >> "$DOTFILES_TEST_LOG"
if [ "${DOTFILES_PACMAN_FAIL:-0}" = 1 ]; then exit 77; fi
exit 0
EOF
    chmod +x "$bin/pacman"
}

run_installer() {
    local home="$1" bin="$2"
    shift 2
    HOME="$home" \
    PATH="$bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$home/.config" \
    DOTFILES_DISTRO_ID=arch \
    DOTFILES_TEST_LOG="$TEST_ROOT/commands.log" \
    bash "$ROOT/install.sh" "$@"
}

assert_no_write_commands() {
    [[ ! -s "$TEST_ROOT/commands.log" ]] || {
        echo "read-only mode invoked a write-capable command:" >&2
        cat "$TEST_ROOT/commands.log" >&2
        return 1
    }
}

readonly_home="$TEST_ROOT/readonly-home"
readonly_bin="$TEST_ROOT/readonly-bin"
mkdir -p "$readonly_home"
make_mock_bin "$readonly_bin"
for command_name in chsh gsettings emerge dnf dnf5; do
    cat > "$readonly_bin/$command_name" <<'EOF'
#!/bin/sh
printf '%s\n' "$0 $*" >> "$DOTFILES_TEST_LOG"
exit 99
EOF
    chmod +x "$readonly_bin/$command_name"
done
: > "$TEST_ROOT/commands.log"
run_installer "$readonly_home" "$readonly_bin" --dry-run --profile generic \
    --set-default-shell --apply-desktop-settings --enable-optional dolphin-emu >/dev/null
assert_no_write_commands
[[ ! -e "$readonly_home/.config/hypr/machine.local.lua" ]]

if command -v script >/dev/null 2>&1; then
    menu_output="$(printf '1\n' | HOME="$readonly_home" PATH="$readonly_bin:/usr/bin:/bin" \
        DOTFILES_DISTRO_ID=arch DOTFILES_TEST_LOG="$TEST_ROOT/commands.log" \
        script -qec "bash '$ROOT/install.sh' --dry-run" /dev/null 2>&1)"
    grep -q '1) Generic' <<<"$menu_output"
    grep -q '2) Zayed laptop' <<<"$menu_output"
    grep -q 'Selected machine profile: generic' <<<"$menu_output"
fi
: > "$TEST_ROOT/commands.log"
run_installer "$readonly_home" "$readonly_bin" --audit --profile generic \
    --set-default-shell --apply-desktop-settings >/dev/null
assert_no_write_commands
[[ ! -e "$readonly_home/.config/hypr/machine.local.lua" ]]

full_home="$TEST_ROOT/full-home"
full_bin="$TEST_ROOT/full-bin"
mkdir -p "$full_home"
make_mock_bin "$full_bin"
make_mock_curl "$full_bin"
make_mock_pacman "$full_bin"
: > "$TEST_ROOT/commands.log"
run_installer "$full_home" "$full_bin" --non-interactive --profile generic >/dev/null
grep -q 'pacman .*hyprland' "$TEST_ROOT/commands.log"
grep -q 'xdg-desktop-portal-hyprland' "$TEST_ROOT/commands.log"
[[ -x "$full_home/.local/bin/oh-my-posh" ]]
[[ -f "$full_home/.config/hypr/wallpapers/torii.jpg" ]]
[[ -f "$full_home/.config/Kvantum/gruvbox-kvantum/gruvbox-kvantum.svg" ]]
[[ -f "$full_home/.config/btop/themes/gruvbox_dark_v2.theme" ]]
[[ -f "$full_home/.themes/torii-zayed.omp.json" ]]
grep -q 'persistent-workspaces.*\[1, 2, 3, 4, 5\]' "$full_home/.config/waybar/config.jsonc"
! grep -q '"interface": "wlp3s0"' "$full_home/.config/waybar/config.jsonc"
grep -q 'profile = "generic"' "$full_home/.config/hypr/machine.local.lua"

rm -f "$full_bin/awww"
cat > "$full_bin/awww" <<'EOF'
#!/bin/sh
if [ "$1" = query ]; then exit 0; fi
printf '%s\n' "$*" >> "$DOTFILES_WALLPAPER_LOG"
EOF
chmod +x "$full_bin/awww"
: > "$TEST_ROOT/wallpaper.log"
for wallpaper_profile in generic zayed-laptop; do
    HOME="$full_home" PATH="$full_bin:/usr/bin:/bin" \
        DOTFILES_MACHINE_PROFILE="$wallpaper_profile" DOTFILES_WALLPAPER_LOG="$TEST_ROOT/wallpaper.log" \
        bash "$full_home/.config/hypr/scripts/wallpaper.sh"
done
grep -q 'torii.jpg' "$TEST_ROOT/wallpaper.log"
wallpaper_path="$full_home/.config/hypr/wallpapers/torii.jpg"
mv "$wallpaper_path" "$wallpaper_path.missing"
HOME="$full_home" PATH="$full_bin:/usr/bin:/bin" DOTFILES_MACHINE_PROFILE=generic \
    bash "$full_home/.config/hypr/scripts/wallpaper.sh" >/dev/null 2>&1
mv "$wallpaper_path.missing" "$wallpaper_path"

rm -f "$full_bin/hyprlock"
cat > "$full_bin/hyprlock" <<'EOF'
#!/bin/sh
config=""
while [ "$#" -gt 0 ]; do
    if [ "$1" = --config ]; then config="$2"; shift 2; else shift; fi
done
grep -q 'path = .*torii.jpg' "$config" || exit 1
EOF
chmod +x "$full_bin/hyprlock"
runtime_dir="$TEST_ROOT/hyprlock-runtime"
mkdir -p "$runtime_dir"
HOME="$full_home" XDG_RUNTIME_DIR="$runtime_dir" PATH="$full_bin:/usr/bin:/bin" \
    DOTFILES_MACHINE_PROFILE=generic bash "$full_home/.config/hypr/scripts/hyprlock.sh"
mv "$wallpaper_path" "$wallpaper_path.missing"
sed -i 's/path = .*torii.jpg/path = screenshot/' "$full_bin/hyprlock"
HOME="$full_home" XDG_RUNTIME_DIR="$runtime_dir" PATH="$full_bin:/usr/bin:/bin" \
    DOTFILES_MACHINE_PROFILE=generic bash "$full_home/.config/hypr/scripts/hyprlock.sh" >/dev/null 2>&1
mv "$wallpaper_path.missing" "$wallpaper_path"

zayed_home="$TEST_ROOT/zayed-home"
mkdir -p "$zayed_home"
run_installer "$zayed_home" "$full_bin" --non-interactive --profile zayed-laptop >/dev/null
grep -q 'profile = "zayed-laptop"' "$zayed_home/.config/hypr/machine.local.lua"
grep -q 'wlp3s0' "$zayed_home/.config/waybar/profiles/zayed-laptop.json"
grep -q '"interface": "wlp3s0"' "$zayed_home/.config/waybar/config.jsonc"
grep -q 'output = "eDP-1"' "$zayed_home/.config/hypr/profiles/zayed-laptop.lua"
grep -q 'mode = "2560x1600@165"' "$zayed_home/.config/hypr/profiles/zayed-laptop.lua"
grep -q 'scale = 2' "$zayed_home/.config/hypr/profiles/zayed-laptop.lua"
! grep -q 'zayed-laptop' "$ROOT/config/hypr/scripts/hyprlock.sh" || true

failure_home="$TEST_ROOT/failure-home"
failure_bin="$TEST_ROOT/failure-bin"
mkdir -p "$failure_home"
make_mock_bin "$failure_bin"
make_mock_curl "$failure_bin"
make_mock_pacman "$failure_bin"
: > "$TEST_ROOT/commands.log"
if DOTFILES_PACMAN_FAIL=1 run_installer "$failure_home" "$failure_bin" --non-interactive --profile generic >/dev/null 2>&1; then
    echo "mandatory package failure unexpectedly succeeded" >&2
    exit 1
fi
[[ ! -e "$failure_home/.config/hypr/hyprland.lua" ]]

packages_only_home="$TEST_ROOT/packages-only-home"
mkdir -p "$packages_only_home"
run_installer "$packages_only_home" "$full_bin" --non-interactive --profile generic --packages-only >/dev/null
[[ ! -e "$packages_only_home/.config/hypr/hyprland.lua" ]]
[[ ! -e "$packages_only_home/.local/bin/oh-my-posh" ]]

repeat_home="$TEST_ROOT/repeat-home"
mkdir -p "$repeat_home"
run_installer "$repeat_home" "$full_bin" --non-interactive --profile generic >/dev/null
printf '%s\n' 'user change' >> "$repeat_home/.config/kitty/kitty.conf"
run_installer "$repeat_home" "$full_bin" --non-interactive --profile generic >/dev/null
backup_count="$(find "$repeat_home/.local/state/dotfiles/backups" -name manifest.tsv -type f 2>/dev/null | wc -l)"
(( backup_count >= 1 ))

echo "installer safety/full-install/profile/idempotence tests: OK"
