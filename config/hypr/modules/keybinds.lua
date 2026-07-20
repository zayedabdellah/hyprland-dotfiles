---------------------
---- MY PROGRAMS ----
---------------------

local machine     = require("machine")
local terminal    = machine.commands.terminal
local fileManager = machine.commands.file_manager
local menu        = machine.commands.menu
local browser     = machine.commands.browser
local osd         = machine.commands.osd

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Programs
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + W",      hl.dsp.exec_cmd(browser))
hl.bind("ALT + SPACE",          hl.dsp.exec_cmd(menu)) -- Now Alt+Space
hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd(machine.commands.waybar_launcher))
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd(machine.commands.hyprlock)) -- Lock Screen

-- Window Management
hl.bind(mainMod .. " + T",      hl.dsp.window.float({ action = "toggle" })) -- Now Super+T
hl.bind(mainMod .. " + V",      hl.dsp.layout("togglesplit"))               -- Now Super+V
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen())                  -- Added Fullscreen

-- Screenshots
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(mainMod .. " + PRINT",     hl.dsp.exec_cmd("grim - | wl-copy"))

-- Move focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move window
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Resize window
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }),  { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }),   { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0, y = -40, relative = true }),  { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0, y = 40, relative = true }),   { repeating = true })

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special Workspace (Magic)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse binds
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- Multimedia (Using Custom OSD Script)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(osd .. " volume up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(osd .. " volume down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(osd .. " volume mute"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })

-- Brightness (Using Custom OSD Script)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(osd .. " brightness up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(osd .. " brightness down"), { locked = true, repeating = true })

-- Playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Move window from special:magic back to current workspace
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.window.move({ workspace = "r+0" }))

-- Center floating window
hl.bind(mainMod .. " + C", hl.dsp.window.center())
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd(terminal .. " --class btop -e btop"))
