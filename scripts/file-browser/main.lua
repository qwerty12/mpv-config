local function lazy_load()
    mp.remove_key_binding("browse-files")
    require('file-browser')
    mp.command("script_binding file_browser/browse-files")
end
mp.add_key_binding(nil, "browse-files", lazy_load)
