-- https://github.com/po5/chapterskip/blob/master/chapterskip.lua @ f4c5da3e7661212eb491cc1d85beafbf951e32f0
-- + https://github.com/po5/chapterskip/pull/2
-- chapterskip.lua
--
-- Ain't Nobody Got Time for That
--
-- This script skips chapters based on their title.

local categories = {
    prologue = "^[Pp]rologue",
    intro = "^[Ii]ntro",
    opening = "^OP/ OP$/^[Oo]pening",
    ending = "^ED/ ED$/^[Ee]nding",
    credits = "^[Cc]redits",
    preview = "[Pp]review$"
}

local options = {
    enabled = true,
    skip_once = true,
    categories = "",
    skip = "",
    verbose = false
}

mp.options = require "mp.options"

function matches(i, title)
    for category in string.gmatch(options.skip, " *([^;]*[^; ]) *") do
        if categories[category:lower()] then
            if string.find(category:lower(), "^idx%-") == nil then
                if title then
                    for pattern in string.gmatch(categories[category:lower()], "([^/]+)") do
                        if string.match(title, pattern) then
                            return true
                        end
                    end
                end
            else
                for pattern in string.gmatch(categories[category:lower()], "([^/]+)") do
                    if tonumber(pattern) == i then
                        return true
                    end
                end
            end
        end
    end
end

local skipped = {}
local parsed = {}

local function set_uosc_property()
    mp.commandv('script-message-to', 'uosc', 'set', 'chapterskip_enabled', options.enabled and 'yes' or 'no')
end

local function set_chapterskip(_, value)
    options.enabled = value == "yes"
    --if options.verbose then
    --    mp.osd_message("chapterskip " .. (options.enabled and "enabled" or "disabled"))
    --end
    set_uosc_property()
end

function chapterskip(_, current)
    mp.options.read_options(options, "chapterskip")
    set_uosc_property()
    if not options.enabled then return end
    for category in string.gmatch(options.categories, "([^;]+)") do
        local name, patterns = string.match(category, " *([^+>]*[^+> ]) *[+>](.*)")
        if name then
            categories[name:lower()] = patterns
        elseif not parsed[category] then
            mp.msg.warn("Improper category definition: " .. category)
        end
        parsed[category] = true
    end
    local chapters = mp.get_property_native("chapter-list")
    local skip = false
    for i, chapter in ipairs(chapters) do
        if (not options.skip_once or not skipped[i]) and matches(i, chapter.title) then
            if i == current + 1 or skip == i - 1 then
                if skip then
                    skipped[skip] = true
                end
                skip = i
            end
        elseif skip then
            if options.verbose then
                mp.osd_message("chapterskip: skipping " .. chapters[skip].title)
            end
            mp.set_property("time-pos", chapter.time)
            skipped[skip] = true
            return
        end
    end
    if skip then
        if options.verbose then
            mp.osd_message("chapterskip: next file")
        end
        if mp.get_property_native("playlist-count") == mp.get_property_native("playlist-pos-1") then
            return mp.set_property("time-pos", mp.get_property_native("duration"))
        end
        mp.commandv("playlist-next")
    end
end

mp.observe_property("chapter", "number", chapterskip)
mp.register_event("file-loaded", function() skipped = {} end)
mp.options.read_options(options, "chapterskip")
mp.register_script_message("set", set_chapterskip)
set_uosc_property()
