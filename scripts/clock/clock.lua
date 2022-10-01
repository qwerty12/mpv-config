-- Mozbugbox's lua utilities for mpv 
-- Copyright (c) 2015-2018 mozbugbox@yahoo.com.au
-- Licensed under GPL version 3 or later

--[[
Show current time on video
Usage: c script_message show-clock [true|yes]
--]]

local assdraw = require('mp.assdraw')

local update_timeout = 10 -- in seconds
local additional_gap = false

-- Class creation function
function class_new(klass)
    -- Simple Object Oriented Class constructor
    local klass = klass or {}
    function klass:new(o)
        local o = o or {}
        setmetatable(o, self)
        self.__index = self
        return o
    end
    return klass
end

function get_osd_size()
    return mp.get_property_number("display-width", 0), mp.get_property_number("display-height", 0)
end

-- Show OSD Clock
local OSDClock = class_new()
function OSDClock:_show_clock()
    -- Show wall clock on bottom right corner
    local osd_w, osd_h = get_osd_size()
    if osd_w == 0 and osd_h == 0 then
        return
    end

    local scale = 1.35
    local fontsize = tonumber(mp.get_property("options/osd-font-size")) / scale
        fontsize = math.floor(fontsize)
    -- require("mp.msg").info(fontsize)
    --
    local vert_gap = not additional_gap and 101 or 151
    local ass = assdraw:ass_new()
    ass:new_event()
    ass:pos(osd_w - 55, osd_h - vert_gap)
    ass:append(string.format("{\\fs%d}", fontsize))
    ass:append(os.date("%I:%M"))
    ass:pos(0, 0)
    mp.set_osd_ass(osd_w, osd_h, ass.text)
    -- msg.info(ass.text, osd_w, osd_h)
end

function clear_osd()
    local osd_w, osd_h = get_osd_size()
    mp.set_osd_ass(osd_w, osd_h, "")
end

function OSDClock:toggle_show_clock(val)
    local trues = {["true"]=true, ["yes"] = true}
    if self.tobj then
        if trues[val] ~= true then
            self.tobj:kill()
            self.tobj = nil
            clear_osd()
            additional_gap = false
        end
    elseif val == nil or trues[val] == true then
        self.tobj = mp.add_periodic_timer(update_timeout,
            function() self:_show_clock() end)
        self:_show_clock()
    end
end

local osd_clock = OSDClock:new()
function toggle_show_clock(v)
    if v == "extra" then
        if osd_clock.tobj ~= nil then
            v = "false"
        else
            additional_gap = true
            v = "true"
        end
    end
    osd_clock:toggle_show_clock(v)
end

mp.register_script_message("show-clock", toggle_show_clock)

