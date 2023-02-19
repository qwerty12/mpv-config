if loadfile(mp.get_script_directory() .. "/../jellyfin/jellyfin.lua")().is_jellyfin_env then
    _G.mp_event_loop = function() end
    return
end
require("freeze-window")