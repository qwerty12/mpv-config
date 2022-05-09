-- change keybinding in seek-to.lua too
local binds = {["toggle-seeker"] = 0, ["paste-timestamp"] = "ctrl+alt+v"}

local function load()
    for name, key in pairs(binds) do
        mp.remove_key_binding(name)
    end
    require("seek-to")
end

for name, key in pairs(binds) do
    local function lazy_load()
        load()
        mp.command("script-binding seek_to/" .. name)
    end
    mp.add_key_binding(key ~= 0 and key or nil, name, lazy_load)
end