local function delay_load()
    mp.unregister_idle(delay_load)
    require('simple-mpv-webui')
end
mp.register_idle(delay_load)