local sub_menu_threshold = 10
local cycle_sub = true

local function update_tracks()
    cycle_sub = true
    local sub_tracks = 0
    local all_tracks = mp.get_property_native('track-list', {})
    for i = 1, #all_tracks do
        if all_tracks[i].type == 'sub' then
            sub_tracks = sub_tracks + 1
            if sub_tracks > sub_menu_threshold then
                cycle_sub = false
                return
            end
        end
    end
end
mp.register_event('start-file', update_tracks)
mp.register_event('file-loaded', update_tracks)
mp.observe_property('tracks-changed', 'native', update_tracks)

mp.add_key_binding("s", 'subsel', function() mp.command(cycle_sub and "cycle sub" or "script-binding uosc/subtitles") end)