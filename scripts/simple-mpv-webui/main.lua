local scoop_home = os.getenv("SCOOP_HOME")
if scoop_home == nil then
    scoop_home = os.getenv("USERPROFILE") .. "\\scoop"
end
local mpv_path = scoop_home .. "\\apps\\mpv-git\\current"
local fw_rules_created_file = mpv_path .. "\\fw_rules_created"

local f = io.open(fw_rules_created_file, "r")
if f ~= nil then
    io.close(f)
    require("simple-mpv-webui")
else
    io.close(io.open(fw_rules_created_file, "w"))

    mp.command_native({
        name = "subprocess",
        playback_only = false,
        detach = true,
        args = {"C:\\Program Files\\AutoHotkey\\AutoHotkey.exe", "/ErrorStdOut", mp.get_script_directory() .. "\\AddMpvFirewallRule.ahk"},
    })

    mp.add_timeout(5, function() require("simple-mpv-webui") end)
end