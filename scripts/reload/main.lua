local function on_file_loaded(event)
    if mp.get_property_bool("demuxer-via-network") and mp.get_property("stream-lavf-o", ""):find("reconnect=1") == nil then
        mp.unregister_event(on_file_loaded)
        require('reload')
    end
end

mp.register_event("file-loaded", on_file_loaded)