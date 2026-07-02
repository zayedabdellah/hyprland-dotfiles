-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("echo 'Xft.dpi: 192' | xrdb -merge")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("gentoo-pipewire-launcher")
    hl.exec_cmd("waybar")
    hl.exec_cmd("waybar -c ~/.config/waybar/config-top.jsonc")
    hl.exec_cmd("~/.config/waybar/scripts/media-daemon.sh")
    hl.exec_cmd("swaync")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("/usr/libexec/hyprpolkitagent")
end)
