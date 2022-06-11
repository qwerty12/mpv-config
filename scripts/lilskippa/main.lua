-- change keybinding in lilskippa.lua too
local binds = {["skip2scene"] = "%", ["skip2black"] = "^", ["skip2silence"] = "&"}

local function load()
    for name, key in pairs(binds) do
        mp.remove_key_binding(name)
    end
    require("lilskippa")
end

for name, key in pairs(binds) do
    local function lazy_load()
        load()
        mp.command("script-binding lilskippa/" .. name)
    end
    mp.add_key_binding(key ~= 0 and key or nil, name, lazy_load)
end