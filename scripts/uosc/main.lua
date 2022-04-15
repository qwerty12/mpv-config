if mp.get_property('osc') == 'yes' then
	return
end
require('uosc')
mp.commandv("load-script", mp.get_script_directory() .. "/osc.lua")
--require('osc-potplayer-box-knob-or-bar-0')