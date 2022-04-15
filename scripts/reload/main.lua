local function on_file_loaded(event)
    if mp.get_property("stream-lavf-o", ""):find("reconnect=1") ~= nil then
        mp.unregister_event(on_file_loaded)
        require('reload')
    end
end

mp.register_event("start-file", on_file_loaded)