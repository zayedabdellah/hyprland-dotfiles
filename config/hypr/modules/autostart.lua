-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("echo 'Xft.dpi: 96' | xrdb -merge")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("gentoo-pipewire-launcher")
    hl.exec_cmd("waybar")
    hl.exec_cmd("waybar -c ~/.config/waybar/config-top.jsonc")
    hl.exec_cmd("~/.config/waybar/scripts/media-daemon.sh")
    hl.exec_cmd("swaync")
    hl.exec_cmd("awww-daemon & sleep 1 && awww img ~/.config/hypr/wallpapers/wallpaper.jpg")
    -- Polkit Agents (Universal detection)
    hl.exec_cmd("command -v hyprpolkitagent >/dev/null && hyprpolkitagent || [ -f /usr/libexec/hyprpolkitagent ] && /usr/libexec/hyprpolkitagent || /usr/lib/hyprpolkitagent")
    hl.exec_cmd("[ -f /usr/lib/polkit-kde-authentication-agent-1 ] && /usr/lib/polkit-kde-authentication-agent-1 || [ -f /usr/libexec/polkit-kde-authentication-agent-1 ] && /usr/libexec/polkit-kde-authentication-agent-1")
end)
