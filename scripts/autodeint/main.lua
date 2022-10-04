local lazy_load = nil

local on_file_loaded = function(_, value)
    if value == "mpeg2video" then
        lazy_load()
    end
end

lazy_load = function()
    mp.unobserve_property(on_file_loaded)
    mp.remove_key_binding("autodeint")
    require('autodeint')
    mp.commandv("script-binding", "autodeint/autodeint")
end

mp.add_key_binding(nil, "autodeint", lazy_load)
mp.observe_property("video-format", "string", on_file_loaded)
