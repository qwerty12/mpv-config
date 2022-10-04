local function lazy_load()
    mp.unregister_script_message("subit")
    require("subit")
    mp.commandv("script-message-to", "subit", "subit")
end
mp.register_script_message("subit", lazy_load)