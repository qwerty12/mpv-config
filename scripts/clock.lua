-- Mozbugbox's lua utilities for mpv 
-- Copyright (c) 2015-2018 mozbugbox@yahoo.com.au
-- Licensed under GPL version 3 or later

--[[
Show current time on video
Usage: c script_message show-clock [true|yes]
--]]

local msg = require("mp.msg")
local utils = require("mp.utils") -- utils.to_string()
local assdraw = require('mp.assdraw')

local initial = true
local update_timeout = 10 -- in seconds

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

-- print content of a lua table
function print_table(tbl)
    msg.info(utils.to_string(tbl))
end

-- Show OSD Clock
local OSDClock = class_new()
function OSDClock:_show_clock()
    -- Show wall clock on bottom right corner
    local osd_w = mp.get_property_number("display-width", 0)
    local osd_h = mp.get_property_number("display-height", 0)
    if osd_w == 0 and osd_h == 0 then
        return
    else
        if initial then
            initial = false
            self:toggle_show_clock(false)
            self:toggle_show_clock(true)
            return
        end
    end

    local scale = 1.6
    local fontsize = tonumber(mp.get_property("options/osd-font-size")) / scale
        fontsize = math.floor(fontsize)
    -- msg.info(fontsize)
    --
    local ass = assdraw:ass_new()
    ass:new_event()
    ass:an(3)
    ass:append(string.format("{\\fs%d}", fontsize))
    ass:append(os.date("%I:%M"))
    ass:an(0)
    mp.set_osd_ass(osd_w, osd_h, ass.text)
    -- msg.info(ass.text, osd_w, osd_h)
end

function clear_osd()
    local osd_w, osd_h, aspect = mp.get_osd_size()
    mp.set_osd_ass(osd_w, osd_h, "")
end

function OSDClock:toggle_show_clock(val)
    local trues = {["true"]=true, ["yes"] = true}
    if self.tobj then
        if trues[val] ~= true then
            self.tobj:kill()
            self.tobj = nil
            clear_osd()
        end
    elseif val == nil or trues[val] == true then
        self.tobj = mp.add_periodic_timer(not initial and update_timeout or 0.1,
            function() self:_show_clock() end)
        self:_show_clock()
    end
end

local osd_clock = OSDClock:new()
function toggle_show_clock(v)
    osd_clock:toggle_show_clock(v)
end

mp.register_script_message("show-clock", toggle_show_clock)

