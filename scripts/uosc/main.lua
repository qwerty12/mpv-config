if mp.get_property('osc') == 'yes' then
	return
end
local script_dir = mp.get_script_directory()
package.path = package.path .. ";" .. script_dir .. "\\scripts\\uosc\\?.lua;"
require('scripts/uosc/main')
