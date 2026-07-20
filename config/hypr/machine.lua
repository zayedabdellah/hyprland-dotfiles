-- Select a portable machine profile without changing the rice's behavior.
-- Generic is deliberately safe. The laptop profile must be selected explicitly
-- with DOTFILES_MACHINE_PROFILE or machine.local.lua.

local function merge(destination, overrides)
    for key, value in pairs(overrides or {}) do
        if type(value) == "table" and type(destination[key]) == "table" then
            merge(destination[key], value)
        else
            destination[key] = value
        end
    end
    return destination
end

local selected = os.getenv("DOTFILES_MACHINE_PROFILE")
if selected == nil or selected == "" then
    selected = "generic"
end

local local_ok, local_config = pcall(require, "machine.local")
if not local_ok and package.searchpath("machine.local", package.path) then
    error("Failed to load config/hypr/machine.local.lua: " .. tostring(local_config))
end

if local_ok then
    if type(local_config) ~= "table" then
        error("config/hypr/machine.local.lua must return a table")
    end
    if local_config.profile ~= nil then
        selected = local_config.profile
    end
end

local profile_ok, profile = pcall(require, "profiles." .. selected)
if not profile_ok then
    error("Invalid machine profile '" .. tostring(selected) .. "'. " .. tostring(profile))
end

if local_ok and local_config.overrides ~= nil then
    profile = merge(profile, local_config.overrides)
end

return profile
