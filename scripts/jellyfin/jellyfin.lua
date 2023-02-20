-- Assumes the following is present in jellyfin-mpv-shim's conf.json:
--[[ {
    "direct_paths": true,
    "enable_osc": false,
    "kb_debug": "f23",
    "kb_kill_shader": "f23",
    "kb_menu": "f23",
    "kb_menu_esc": "f23",
    "kb_menu_ok": "f23",
    "kb_pause": "f23",
    "kb_watched": "i",
    "media_keys": false,
    "menu_mouse": false,
    "mpv_ext": true,
    "mpv_ext_ipc": "jellyfinmpv",
    "mpv_ext_no_ovr": true,
    "mpv_ext_path": "C:\\Users\\fp\\scoop\\apps\\mpv-git\\current\\mpv.exe",
    "remote_direct_paths": true,
    "seek_down": -30,
    "seek_up": 30,
    "thumbnail_enable": false,
} ]]

local is_jellyfin_env = mp.get_property("input-ipc-server") == "jellyfinmpv"

local function init_window_shit()
    local window_shit = {
        mpv_hwnd = nil
    }
    window_shit.ffi = require("ffi")

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

    return window_shit
end

local function save_state()
    mp.command("write-watch-later-config ; script-message-to auto_save_state skip-delete-state")
end

local function on_not_core_idle(_, value)
    if value then return end
    mp.unobserve_property(on_not_core_idle)
    local channels = mp.get_property_number("audio-params/channel-count", -1)
    if channels == -1 then return end
    if channels > 2 then
        mp.command("apply-profile downmix-51")
    else
        mp.command("apply-profile louder-2ch")
    end
end

local function main()
    mp.register_script_message("quit", function()
        if not is_jellyfin_env then
            mp.command("quit")
        else
            mp.commandv("script-message", "custom-bind", 'bind1')
        end
    end)
    mp.register_script_message("prev", function()
        save_state()
        if not is_jellyfin_env then
            mp.command("playlist-prev")
        else
            mp.commandv("script-message", "custom-bind", 'bind4')
        end
    end)
    mp.register_script_message("next", function()
        save_state()
        if not is_jellyfin_env then
            mp.command("playlist-next")
        else
            mp.commandv("script-message", "custom-bind", 'bind5')
        end
    end)
    if not is_jellyfin_env then return end

    -- apply some profiles manually because, for whatever reason, jellyfin's shim does not play nice with mpv's auto profiles
    mp.set_property("load-auto-profiles", "no")
    mp.set_property("priority", "high")
    mp.set_property("resume-playback", "no")
    mp.set_property("keep-open", "no")
    local window_shit = init_window_shit()
    mp.observe_property("pause", "bool", function(_, value)
        mp.set_property_native("ontop", not value)
    end)
    mp.observe_property("vo-configured", "bool", function(_, value)
        if not value then
            window_shit.mpv_hwnd = nil
        end
    end)
    mp.register_event("file-loaded", function()
        mp.unobserve_property(on_not_core_idle)
        window_shit.do_focus()
        mp.observe_property("core-idle", "bool", on_not_core_idle)
    end)
end

return { main = main, is_jellyfin_env = is_jellyfin_env }
