local function delay_load()
    mp.unregister_idle(delay_load)
    require('simple-mpv-webui')
end

local function on_vo_configured(_, value)
    if not value then return end
    mp.unobserve_property(on_vo_configured)
    mp.register_idle(delay_load)
end
mp.observe_property("vo-configured", "bool", on_vo_configured)