local function delay_load()
    mp.unregister_idle(delay_load)
    require('user-input')
end
mp.register_idle(delay_load)