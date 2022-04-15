-- https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/ontop-playback.lua @ c48de9e399cad3c1b181d0e0e53841e5c15e7610
--makes mpv disable ontop when pausing and re-enable it again when resuming playback
--please note that this won't do anything if ontop was not enabled before pausing

local was_ontop = false

mp.observe_property("pause", "bool", function(name, value)
    local ontop = mp.get_property_native("ontop")
    if value then
        if ontop then
            mp.set_property_native("ontop", false)
            was_ontop = true
        end
    else
        if was_ontop and not ontop then
            mp.set_property_native("ontop", true)
        end
        was_ontop = false
    end
end)
