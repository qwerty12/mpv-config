local sub_tracks = 0

local function update_tracks()
    sub_tracks = 0
    local all_tracks = mp.get_property_native('track-list', {})
    for i = 1, #all_tracks do
        if all_tracks[i].type == 'sub' then
            sub_tracks = sub_tracks + 1
        end
    end
end
mp.register_event('start-file', update_tracks)
mp.register_event('file-loaded', update_tracks)
mp.observe_property('tracks-changed', 'native', update_tracks)

mp.add_key_binding("s", 'subsel', function()
    if sub_tracks <= 10 then
        mp.command("cycle sub")
    else
        mp.command("script-binding uosc/subtitles")
    end
end)