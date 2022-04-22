-- https://github.com/oltodosel/mpv-scripts/blob/master/speed_osd3.lua @ 2c968477fc20332ce1f4e3a71346f2187d4dfd44
-- recalculates osd-msg3 timecodes with playback-speed != 1

function disp_time(time)
    local hours = math.floor(time/3600)
    local minutes = math.floor((time % 3600)/60)
    local seconds = math.floor(time % 60)
    
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function speed_change(name, value)
    local tp = mp.get_property_number("time-pos")
    local speed = mp.get_property_number("speed")
    local dur = mp.get_property_number("duration")
    local pp = mp.get_property_number("percent-pos")

    if tp ~= nil and tp > 0.5 and speed ~= nil and dur ~= nil and pp ~= nil then
        mp.command(
            string.format('show-text "Speed: %.2f\n%s / %s (%i%%)"',
                speed,
                disp_time(tp / speed),
                disp_time(dur / speed),
                pp
            )
        )
    end
end

function started()
    local speed = mp.get_property_number("speed")
    local dur = mp.get_property_number("duration")

    if speed ~= nil and dur ~= nil then
        mp.set_property("osd-playing-msg", 
            string.format("[${playlist-pos-1}/${playlist-count}] ${filename} (%s)",
                disp_time(dur / speed)
            )
        )
    else
        mp.set_property("osd-playing-msg", "")
    end
end

mp.register_event("file-loaded", started)
mp.observe_property("speed", "number", speed_change)
