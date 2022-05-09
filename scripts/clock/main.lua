local function lazy_load(...)
    mp.unregister_script_message("show-clock")
    require("clock")
    mp.commandv("script-message-to", "clock", "show-clock", unpack({...}))
end
mp.register_script_message("show-clock", lazy_load)