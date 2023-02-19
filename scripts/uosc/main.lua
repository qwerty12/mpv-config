if mp.get_property('osc') == 'yes' then
    _G.mp_event_loop = function() end
    return
end
package.path = package.path .. ";" .. mp.get_script_directory() .. "/scripts/?.lua;"
require('uosc')
