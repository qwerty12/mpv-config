local function delay_load()
    mp.unregister_idle(delay_load)
    require('scripts/SmartCopyPaste')
end
mp.register_idle(delay_load)