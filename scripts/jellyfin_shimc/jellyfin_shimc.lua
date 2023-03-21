-- Assumes the following is present in jellyfin-mpv-shim's conf.json:
--[[ {
    "connect_retry_mins": 1,
    "direct_paths": true,
    "enable_osc": false,
    "kb_debug": "f23",
    "kb_kill_shader": "f23",
    "kb_menu": "f23",
    "kb_menu_down": "f23",
    "kb_menu_esc": "f23",
    "kb_menu_left": "f23",
    "kb_menu_ok": "f23",
    "kb_menu_right": "f23",
    "kb_menu_up": "f23",
    "kb_pause": "f23",
    "kb_watched": "i",
    "lang_filter": "eng,und,mis,mul,zxx",
    "lang_filter_sub": true,
    "media_keys": false,
    "menu_mouse": false,
    "mpv_ext": true,
    "mpv_ext_ipc": "jellyfinmpv",
    "mpv_ext_no_ovr": true,
    "mpv_ext_path": "C:\\Users\\fp\\scoop\\apps\\mpv-git\\current\\mpv.exe",
    "player_name": "mpv",
    "remote_direct_paths": true,
    "seek_down": -30,
    "seek_up": 30,
    "shader_pack_enable": false,
    "skip_intro_prompt": true,
    "thumbnail_enable": false,
    "thumbnail_osc_builtin": false,
} ]]

local is_jellyfin_env = mp.get_property("input-ipc-server") == "jellyfinmpv"

local function init_window_shit()
    local window_shit = {
        mpv_hwnd = nil,
        ffi = require("ffi")
    }

    window_shit.ffi.cdef [[
        void* __stdcall FindWindowExA(void *hWndParent, void *hWndChildAfter, const char *lpszClass, const char *lpszWindow);
        unsigned int __stdcall GetWindowThreadProcessId(void *hWnd, unsigned int *lpdwProcessId);
        bool __stdcall IsIconic(void *hWnd);
        bool __stdcall ShowWindow(void *hWnd, int nCmdShow);
        bool __stdcall SetForegroundWindow(void *hWnd);
        void __stdcall SwitchToThisWindow(void *hWnd, bool fUnknown);
        void* __stdcall GetForegroundWindow();
        bool __stdcall AttachThreadInput(unsigned int idAttach, unsigned int idAttachTo, bool fAttach);
        bool __stdcall IsHungAppWindow(void *hwnd);
        unsigned int __stdcall GetCurrentThreadId();
        bool __stdcall BringWindowToTop(void *hWnd);
        void* __stdcall SetActiveWindow(void *hWnd);
    ]]

    window_shit.get_mpv_hwnd = function()
        local hwnd = nil
        local our_pid = mp.get_property_number("pid")
        local hwnd_pid = window_shit.ffi.new("unsigned int[1]")

        repeat
            hwnd = window_shit.ffi.C.FindWindowExA(nil, hwnd, "mpv", nil)
            if hwnd ~= nil then
                window_shit.ffi.C.GetWindowThreadProcessId(hwnd, hwnd_pid)
                if hwnd_pid[0] == our_pid then
                    break
                end
            end
        until hwnd == nil

        return hwnd
    end

    window_shit.focus_window = function(force)
        if window_shit.mpv_hwnd == nil then
            window_shit.mpv_hwnd = window_shit.get_mpv_hwnd()
            if window_shit.mpv_hwnd == nil then return end
        end
        local hwnd_fg = window_shit.ffi.C.GetForegroundWindow()
        if hwnd_fg == window_shit.mpv_hwnd then return end

        local tid_mpv = 0
        local tid_fg = 0
        if force then
            if not window_shit.ffi.C.IsHungAppWindow(hwnd_fg) then
                tid_mpv = window_shit.ffi.C.GetCurrentThreadId()
                tid_fg = window_shit.ffi.C.GetWindowThreadProcessId(hwnd_fg, nil)
                if not window_shit.ffi.C.AttachThreadInput(tid_mpv, tid_fg, true) then
                    tid_fg = 0
                end
            end
        end

        if window_shit.ffi.C.IsIconic(window_shit.mpv_hwnd) then
            window_shit.ffi.C.ShowWindow(window_shit.mpv_hwnd, 9) --SW_RESTORE
        end
        window_shit.ffi.C.SetForegroundWindow(window_shit.mpv_hwnd)

        if force then
            window_shit.ffi.C.SetForegroundWindow(window_shit.mpv_hwnd)
            window_shit.ffi.C.SetActiveWindow(window_shit.mpv_hwnd)
            -- TODO: Use `keybd_event` to send VK_MENU x2 and retry SetForegroundWindow: https://github.com/Lexikos/AutoHotkey_L/blob/master/source/window.cpp#L320
            window_shit.ffi.C.SwitchToThisWindow(window_shit.mpv_hwnd, true)
            window_shit.ffi.C.BringWindowToTop(window_shit.mpv_hwnd)
            if tid_fg ~= 0 then
                window_shit.ffi.C.AttachThreadInput(tid_mpv, tid_fg, false)
            end
        end
    end

    window_shit.do_focus = function()
        if not window_shit.mpv_hwnd or not mp.get_property_bool("focused") then
            pcall(window_shit.focus_window, false)
            if not mp.get_property_bool("focused") then
                pcall(window_shit.focus_window, true)
            end
        end
    end

    mp.observe_property("vo-configured", "bool", function(_, value)
        if not value then
            window_shit.mpv_hwnd = nil
        end
    end)

    return window_shit
end

local function save_state()
    mp.command("write-watch-later-config ; script-message-to auto_save_state skip-delete-state")
end

local function main()
    mp.register_script_message("quit", function()
        if not is_jellyfin_env then
            mp.command("quit")
        else
            -- found with an amazing print(event) added to handle_client_message() in player.py
            mp.commandv("script-message", "custom-bind", "bind1")
        end
    end)
    mp.register_script_message("prev", function()
        save_state()
        if not is_jellyfin_env then
            mp.command("playlist-prev")
        else
            mp.commandv("script-message", "custom-bind", "bind4")
        end
    end)
    mp.register_script_message("next", function()
        save_state()
        if not is_jellyfin_env then
            mp.command("playlist-next")
        else
            mp.commandv("script-message", "custom-bind", "bind5")
        end
    end)
    mp.register_script_message("seek-forward-uosc", function()
        if not is_jellyfin_env then
            mp.command("no-osd seek 5")
        else
            mp.commandv("script-message", "custom-bind", "bind16")
        end
    end)

    if not is_jellyfin_env then
        -- Exit fullscreen at the end of a playlist
        mp.observe_property("eof-reached", "bool", function(_, value)
            if value then mp.set_property_bool("fullscreen", false) end
        end)

        return
    end

    mp.set_property("keep-open", "no")
    mp.add_forced_key_binding("LEFT", nil, function() mp.command("script-message custom-bind bind15 ; osd-msg show-progress ; script-binding uosc/flash-timeline") end, {repeatable = true})
    mp.add_forced_key_binding("RIGHT", nil, function() mp.command("script-message custom-bind bind16 ; osd-msg show-progress ; script-binding uosc/flash-timeline") end, {repeatable = true})
    mp.add_forced_key_binding("DOWN", nil, function() mp.command("script-message custom-bind bind18 ; osd-msg show-progress ; script-binding uosc/flash-timeline") end, {repeatable = true})
    mp.add_forced_key_binding("UP", nil, function() mp.command("script-message custom-bind bind17 ; osd-msg show-progress ; script-binding uosc/flash-timeline") end, {repeatable = true})
    local window_shit = init_window_shit()
    local resume_enable_timer = mp.add_timeout(5, function() mp.set_property_bool("resume-playback", true) end)
    resume_enable_timer:kill()
    mp.register_event("file-loaded", function()
        window_shit.do_focus()
    end)
    mp.observe_property("vo-configured", "bool", function(_, value)
        resume_enable_timer:kill()
        if not value then
            mp.set_property_bool("resume-playback", false)
        else
            resume_enable_timer:resume()
        end
    end)
end

return { main = main, is_jellyfin_env = is_jellyfin_env }
