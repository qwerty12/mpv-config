-- https://github.com/yuzhen1024/quick_speed_toggle/blob/master/speedtoggle.lua @ 8fbfc23a814d985142c2e4b281167d5a7462ce6d
local save_speed = mp.get_property("speed")
if tonumber(save_speed) == 1 then save_speed = "1.25" end

local function speed_toggle(n)
	if tonumber(n)==1 then
		mp.set_property("speed", save_speed)
	elseif n~=1 then
		save_speed = mp.get_property("speed")
		mp.set_property("speed", "1")
	end
end
mp.add_key_binding("z", "speed_toggle", function() speed_toggle(mp.get_property("speed")) end)

---
local function has_sub()
	local all_tracks = mp.get_property_native('track-list', {})
	for i = 1, #all_tracks do
		if all_tracks[i].type == 'sub' then
			return true
		end
	end
	return false
end

local function is_likely_show(path)
	return (path:find("\\Downloads\\TV\\", 1, true) ~= nil) or 
	((path:find("\\Downloads\\src1\\", 1, true) ~= nil or path:find("\\Downloads\\src2\\", 1, true) ~= nil) and 
	 (path:find(".*[xhXH]26[45]*") ~= nil or path:find(".*[Ss]%d%d%d?[Ee]%d%d%d?*") ~= nil))
end

local last_observed_speed = "1.00"
local is_show_playlist = -1
local function speed_up_shows()
	local speed_is_1 = tonumber(mp.get_property("speed")) == 1
	local is_resuming = not mp.get_property_bool("terminal") and mp.get_property("start", "none") ~= "none"

	if is_show_playlist == -1 then
		is_show_playlist = is_likely_show(mp.get_property("playlist/0/filename"))
		if is_show_playlist then
			mp.observe_property("speed", "string", function(name, value)
				if value ~= nil and tonumber(value) ~= 1 then last_observed_speed = value end
			end)
		end
	end

	if not is_show_playlist then
		if not is_resuming and not speed_is_1 then
			save_speed = "1.25"
			mp.set_property("speed", "1")
		end
		return
	end

	if not is_resuming and speed_is_1 and has_sub() and is_likely_show(mp.get_property("path")) then
		save_speed = "1.00"
		mp.set_property("speed", tonumber(last_observed_speed) ~= 1 and last_observed_speed or "1.25")
	end
end
mp.register_event("file-loaded", speed_up_shows)