local function lazy_load(...)
    mp.unregister_script_message("delete_file")
    require('src/delete-current-file')
    mp.commandv("script-message-to", "delete_current_file", "delete_file", unpack({...}))
end
mp.register_script_message("delete_file", lazy_load)