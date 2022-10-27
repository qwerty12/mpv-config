if mp.get_property('osc') == 'yes' then
	return
end
package.path = package.path .. ";" .. mp.get_script_directory() .. "/scripts/?.lua;"
require('uosc')
