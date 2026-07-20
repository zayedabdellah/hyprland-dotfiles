------------------
---- MONITORS ----
------------------

local machine = require("machine")

hl.monitor({
    output   = machine.monitor.output,
    mode     = machine.monitor.mode,
    position = machine.monitor.position,
    scale    = machine.monitor.scale,
})

-- Persistent Workspaces on the selected display.
if machine.workspace.monitor then
    for w = machine.workspace.first, machine.workspace.last do
        hl.workspace_rule({ workspace = tostring(w), monitor = machine.workspace.monitor, persistent = true })
    end
end
