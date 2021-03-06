local sub_menu_threshold = 10
local cycle_sub = true

local function update_track_count()
    cycle_sub = true
    local sub_tracks_count = 0
    local all_tracks = mp.get_property_native("track-list", {})
    local all_tracks_len = #all_tracks
    for i = 1, all_tracks_len do
        if all_tracks[i].type == "sub" then
            sub_tracks_count = sub_tracks_count + 1
            if sub_tracks_count > sub_menu_threshold then
                cycle_sub = false
                return
            end
        end
    end
end
mp.register_event("file-loaded", update_track_count)
mp.add_forced_key_binding("s", "subsel", function() mp.command(cycle_sub and "cycle sub" or "script-binding uosc/subtitles") end)

local function select_sdh_if_no_ext_sub()
    local current_sid = mp.get_property_number("sid", -1)
    local new_sid = -1
    local all_tracks = mp.get_property_native("track-list", {})
    for i = 1, #all_tracks do
        local track = all_tracks[i]
        if track.type == "sub" then
            if track.external and track.id == current_sid then
                return
            end

            if track.title == "SDH" and track.lang:find("^eng?") ~= nil then
                new_sid = track.id
            end
        end
    end

    if new_sid ~= -1 then
        mp.set_property_number("sid", new_sid)
    end
end
mp.register_event("file-loaded", select_sdh_if_no_ext_sub)

-- local x = 0
-- local properties = mp.get_property_native('property-list', {})
-- local txt = ""
-- for _,property in ipairs(properties) do
--     txt = txt .. property .. ": " .. mp.get_property(property, "") .. "\r\n"
-- end
-- file = io.open(x .. ".txt", "w")
-- x = x + 1
-- file:write(txt)
-- file:close()