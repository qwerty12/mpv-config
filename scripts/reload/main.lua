local function on_file_loaded(event)
    if mp.get_property("stream-open-filename", ""):find("^%a%a%a%a?%a?://") ~= nil then
        mp.unregister_event(on_file_loaded)
        require('reload')
    end
end

mp.register_event("start-file", on_file_loaded)