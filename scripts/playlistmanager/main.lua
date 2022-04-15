local function lazy_load(...)
    mp.unregister_script_message("playlistmanager")
    require("playlistmanager")
    mp.commandv("script-message-to", "playlistmanager", "playlistmanager", unpack({...}))
end
mp.register_script_message("playlistmanager", lazy_load)