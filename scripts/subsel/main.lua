local sub_menu_threshold = 10
local cycle_sub = true
local secondary_sub_profile_applied = false

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
    if secondary_sub_profile_applied then
        secondary_sub_profile_applied = false
        mp.command("no-osd apply-profile secondary-subs restore")
    end
    if loadfile(mp.get_script_directory() .. "/../jellyfin_shimc/jellyfin_shimc.lua")().is_jellyfin_env then
        mp.set_property("sid", "auto") -- work-around Jellyfin's bad automatic subtitle lang selection
        ffi.C.Sleep(150)
        mp.dispatch_events(false)
    end
    local new_sid = -1
    local first_sid = -1
    local del, gle = -1, -1

    local current_sid = mp.get_property_number("sid", -1)
    local all_tracks = mp.get_property_native("track-list", {})
    local filename_no_ext_lower = nil

    for i = 1, #all_tracks do
        local track = all_tracks[i]
        if track.type == "sub" then
            --mp.msg.error(require("mp.utils").format_json(track))

            local lang = track.lang

            if not track.external then
                if ((lang and lang:find("^eng?") ~= nil)) and ((track["hearing-impaired"]) or (track.title and track.title:find("SDH") ~= nil)) then
                    new_sid = track.id
                end
            else
                local is_del, is_gle = false, false
                if del == -1 then
                    is_del = lang == "del"
                end
                if not is_del and gle == -1 then
                    is_gle = lang == "gle"
                end

                if is_del or is_gle then
                    if filename_no_ext_lower == nil then
                        filename_no_ext_lower = mp.get_property("filename/no-ext", ""):lower()
                    end

                    if track.title:lower():sub(1, #filename_no_ext_lower) == filename_no_ext_lower then
                        if is_del then
                            del = track.id
                        else
                            gle = track.id
                        end
                    end
                end
            end

            if first_sid == -1 then
                first_sid = track.id
            end
        end
    end

    if gle ~= -1 and del ~= -1 then
        if del ~= current_sid then
            mp.set_property_number("sid", del)
        end
        mp.set_property_number("secondary-sid", gle)
        secondary_sub_profile_applied = true
        mp.command("no-osd apply-profile secondary-subs")
        return
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
