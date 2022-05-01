-- https://github.com/kungfubeaner/mpv-ontop-only-while-playing-lua/blob/master/on_top_only_while_playing.lua @ 67fc6511c4f2d4c2cf1abb3b519d8d119548e87b
-- =============================================
-- Ontop Only When Playing v1.0                |
-- Author: David Gomez                         |
-- =============================================
-- changes the behavior of ontop mode to only  |
-- stay on top only while playing, and only if |
-- if ontop is currently enabled               |
-- =============================================

local was_ontop = mp.get_property_native("ontop")

local function f_load(event)
	if was_ontop then
		mp.set_property_native("ontop", true)
	end
end
mp.register_event("file-loaded", f_load)

mp.observe_property("pause", "bool", function(name, value)
	local ontop = mp.get_property_native("ontop")
	if value then
		mp.set_property_native("ontop", false)
		was_ontop = ontop
	else
		local is_idle = mp.get_property_native("playback-abort")
		if is_idle then
			mp.set_property_native("ontop", false)
			was_ontop = ontop
		else
			if was_ontop then
				mp.set_property_native("ontop", true)
			end
		end
	end
end)
