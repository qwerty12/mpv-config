-- https://github.com/yuzhen1024/quick_speed_toggle/blob/master/speedtoggle.lua @ 8fbfc23a814d985142c2e4b281167d5a7462ce6d
save_speed = mp.get_property("speed")
if tonumber(save_speed) == 1 then
	save_speed = "1.25"
end

local function speed_toggle(n)
	if tonumber(n)==1 then
		mp.set_property("speed", save_speed)
	elseif  n~=1 then
		save_speed = mp.get_property("speed")
		mp.set_property("speed", "1")
	end
end
mp.add_key_binding("z", "speed_toggle", function() speed_toggle(mp.get_property("speed")) end)