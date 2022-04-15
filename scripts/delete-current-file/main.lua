local function delay_load()
    mp.unregister_idle(delay_load)
    require('src/delete-current-file')
end
mp.register_idle(delay_load)