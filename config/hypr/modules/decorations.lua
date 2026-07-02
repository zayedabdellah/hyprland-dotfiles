-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 8,
        gaps_out = 14,
        border_size = 2,
        col = {
            active_border   = { colors = {"rgba(ff6a00ee)"} },
            inactive_border = "rgba(282828aa)",
        },
        resize_on_border = true,
        allow_tearing = false,
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 0.88,
        shadow = {
            enabled      = true,
            range        = 25,
            render_power = 4,
            color        = "rgba(1c1c1caa)",
        },
        blur = {
            enabled   = true,
            size      = 12,
            passes    = 4,
            vibrancy  = 0.2,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Bezier Curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("bouncy",         { type = "bezier", points = { {0.34, 1.56}, {0.64, 1}    } })
hl.curve("smooth",         { type = "bezier", points = { {0.25, 1},    {0.5, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

-- Animations
hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 6,    bezier = "easeOutQuint" })

-- Dynamic Overshoot Layout
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.0,  bezier = "bouncy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.0,  bezier = "bouncy",      style = "popin 75%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 3.0,  bezier = "smooth" }) -- Error fixed: style removed

hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 2,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 2,    bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })

hl.animation({ leaf = "workspaces",    enabled = true,  speed = 4.5,  bezier = "bouncy",    style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 4.5,  bezier = "bouncy",    style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 4.5,  bezier = "bouncy",    style = "slide" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })