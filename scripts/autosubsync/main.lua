local function lazy_load()
    mp.remove_key_binding("autosubsync-menu")
    require('autosubsync')
    mp.command("script_binding autosubsync/autosubsync-menu")
end
mp.add_key_binding("n", "autosubsync-menu", lazy_load)
