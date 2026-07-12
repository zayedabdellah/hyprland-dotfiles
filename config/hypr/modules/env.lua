-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_SIZE", "48")       -- Doubled for 200% screen scale
hl.env("HYPRCURSOR_SIZE", "48")   -- Doubled for 200% screen scale

-- Toolkit Backend --
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- XDG Specifications --
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("SHELL", "/usr/bin/fish")

-- QT Specific Tuning (Split Scaling Strategy) --
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "0")       -- Keep this at 0
hl.env("QT_ENABLE_HIGHDPI_SCALING", "1")         -- CHANGE THIS FROM "0" TO "1"
hl.env("QT_SCALE_FACTOR_ROUNDING_POLICY", "PassThrough") -- ADD THIS LINE
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_NO_XDG_DESKTOP_PORTAL", "1")

-- GTK Specific Tuning --
hl.env("GTK_THEME", "gruvbox-dark-gtk")
hl.env("GDK_SCALE", "2")                     -- Forces explicit 200% scaling on GTK3/4 apps

-- NVIDIA Support Variables --
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("WLR_DRM_NO_ATOMIC", "1")

---------------------------------
---- XWAYLAND SCALING FIX -------
---------------------------------

-- This stops Hyprland from blurrily auto-stretching non-Wayland applications
hl.config({
    xwayland = {
        force_zero_scaling = true
    }
})
