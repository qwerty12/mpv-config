if mp.get_property('osc') == 'yes' then
    _G.mp_event_loop = function() end
    return
end

local __real_script_directory = mp.get_script_directory()
_G.mp.get_script_directory = function()
	return __real_script_directory .. "/scripts/uosc"
end

package.path = package.path .. ";" .. __real_script_directory .. "/scripts/?.lua;" .. __real_script_directory .. "/scripts/uosc/?.lua;"
require('uosc/main')
