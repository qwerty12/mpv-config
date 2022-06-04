local function lazy_load()
    mp.unregister_script_message("init_trakt_and_set_watched")
    require("trakt-mpv")
    mp.commandv("script-message-to", "trakt_mpv", "init_trakt_and_set_watched")
end
mp.register_script_message("init_trakt_and_set_watched", lazy_load)