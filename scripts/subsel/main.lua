local sub_menu_threshold = 10
local cycle_sub = true

local ffi = require("ffi")
ffi.cdef [[
void __stdcall Sleep(unsigned long dwMilliseconds);
]]

local function update_track_count()
    cycle_sub = true
    local sub_tracks_count = 0
    local all_tracks = mp.get_property_native("track-list", {})
    for i = 1, #all_tracks do
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
    if loadfile(mp.get_script_directory() .. "/../jellyfin_shimc/jellyfin_shimc.lua")().is_jellyfin_env then
        mp.set_property("sid", "auto") -- work-around Jellyfin's bad automatic subtitle lang selection
        ffi.C.Sleep(100)
    end
    local current_sid = mp.get_property_number("sid", -1)
    local new_sid = -1
    local first_sid = -1
    local all_tracks = mp.get_property_native("track-list", {})
    for i = 1, #all_tracks do
        local track = all_tracks[i]
        if track.type == "sub" then
            if track.external and track.id == current_sid then
                return
            end

            if ((track.lang and track.lang:find("^eng?") ~= nil)) and ((track["hearing-impaired"]) or (track.title and track.title:find("SDH") ~= nil)) then
                new_sid = track.id
            elseif first_sid == -1 then
                first_sid = track.id
            end
        end
    end

    if current_sid == -1 and new_sid == -1 and first_sid ~= -1 and all_tracks[first_sid]["lang"] == nil then
        new_sid = first_sid
    end

    if new_sid ~= -1 then
        mp.set_property_number("sid", new_sid)
    end
end

--local count = 0
mp.register_event("file-loaded", function()
-- local properties = mp.get_property_native('property-list', {})
-- local txt = ""
-- for _,property in ipairs(properties) do
--     txt = txt .. property .. ": " .. mp.get_property(property, "") .. "\r\n"
-- end
-- local dest_file = io.open(os.getenv("TEMP") .. "\\" .. count .. "__mp__properties__.txt", "w")
-- count = count + 1
-- dest_file:write(txt)
-- dest_file:close()

    mp.add_timeout(1.2, select_sdh_if_no_ext_sub)
end)
