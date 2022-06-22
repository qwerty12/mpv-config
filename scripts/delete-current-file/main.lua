local function lazy_load(...)
    mp.unregister_script_message("delete-file")
    require('delete-current-file')
    mp.commandv("script-message-to", "delete_current_file", "delete-file", unpack({...}))
end
mp.register_script_message("delete-file", lazy_load)