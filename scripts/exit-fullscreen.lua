-- https://raw.githubusercontent.com/zc62/mpv-scripts/master/exit-fullscreen.lua @ b2852159a9b5e40fa5194ee65bf357cba5ff1c63
-- Exit fullscreen when playback ends, if keep-open=yes

mp.observe_property("eof-reached", "bool", function(name, value)
    if value then
        if mp.get_property_number('playlist-pos-1') == mp.get_property_number('playlist-count') then
            mp.set_property("fullscreen", "no")
        end
    end
end)
