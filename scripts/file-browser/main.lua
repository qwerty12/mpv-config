if loadfile(mp.get_script_directory() .. "/../jellyfin/jellyfin.lua")().is_jellyfin_env then
    _G.mp_event_loop = function() end
    return
end
local function lazy_load()
    mp.remove_key_binding("browse-files")
    require('file-browser')
    mp.command("script_binding file_browser/browse-files")
end
mp.add_key_binding(nil, "browse-files", lazy_load)
