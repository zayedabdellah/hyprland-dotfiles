# ~/.config/fish/config.fish

if status is-interactive
    set -U fish_color_command ff6a00
    set -U fish_color_error 458588
    set -U fish_color_param e2e2e9
end

# Keep these global exports
set -gx XDG_CURRENT_DESKTOP Hyprland
set -gx XDG_SESSION_TYPE wayland

# Standard defaults (Native apps look normal)
set -gx QT_AUTO_SCREEN_SCALE_FACTOR 0

fish_add_path ~/go/bin
fish_add_path ~/.local/bin

alias wine="prime-run mangohud /home/zayed/.local/share/GE/GE-Proton11-1/files/bin/wine"
