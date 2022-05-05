local function load()
    mp.unregister_script_message("open-page")
    mp.remove_key_binding("open-search-page")
    require("search-page")
end

local function lazy_load(...)
    load()
    mp.commandv("script-message-to", "search_page", "open-page", unpack({...}))
end
mp.register_script_message("open-page", lazy_load)

local function lazy_load2()
    load()
    mp.command("script-binding search_page/open-search-page")
end
mp.add_key_binding("f12", "open-search-page", lazy_load2)