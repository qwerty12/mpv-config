local bit = require("bit")
local ffi = require("ffi")
ffi.cdef [[
void* __stdcall FindWindowExA(void *hWndParent, void *hWndChildAfter, const char *lpszClass, const char *lpszWindow);
unsigned int __stdcall GetWindowThreadProcessId(void *hWnd, unsigned int *lpdwProcessId);
unsigned long __stdcall GetWindowLongPtrW(void *hWnd, int nIndex);
int64_t __stdcall SetWindowLongPtrW(void *hWnd, int nIndex, unsigned long dwNewLong);
const char *GetCommandLineA();
]]

local GWL_STYLE = -16
local WS_SYSMENU = 0x00080000

local mpv_hwnd = nil
local function get_mpv_hwnd()
    local hwnd = nil
    local our_pid = mp.get_property_number("pid")
    local hwnd_pid = ffi.new("unsigned int[1]")

    repeat
        hwnd = ffi.C.FindWindowExA(nil, hwnd, "mpv", nil)
        if hwnd ~= nil then
            ffi.C.GetWindowThreadProcessId(hwnd, hwnd_pid)
            if hwnd_pid[0] == our_pid then
                break
            end
        end
    until hwnd == nil

    return hwnd
end

local function disable_ws_sysmenu()
    local ws_style = ffi.C.GetWindowLongPtrW(mpv_hwnd, GWL_STYLE)
    if ws_style ~= 0 and bit.band(ws_style, WS_SYSMENU) == WS_SYSMENU then
        ffi.C.SetWindowLongPtrW(mpv_hwnd, GWL_STYLE, bit.band(ws_style, bit.bnot(WS_SYSMENU)))
        return true
    end
    return false
end

local another_tick = ffi.string(ffi.C.GetCommandLineA()):find("--fullscreen") ~= nil and 0 or -1
local timer = nil
timer = mp.add_periodic_timer(1, function()
    if not mp.get_property_bool("fullscreen") then
        another_tick = -1
        timer:kill()
        return
    end
    if disable_ws_sysmenu() then
        if another_tick == -1 then
            timer:kill()
        else
            another_tick = another_tick + 1
            if another_tick % 2 == 0 then
                another_tick = -1
                timer:kill()
            end
        end
    end
end)
timer:kill()

local function on_fs_change(_, value)
    if not value then return end
    if timer:is_enabled() then return end

    if another_tick == -1 and disable_ws_sysmenu() then
        return
    end
    timer:resume()
end

local function on_focused(_, value)
    if not value then return end
    mp.unobserve_property(on_focused)

    mpv_hwnd = get_mpv_hwnd()
    if mpv_hwnd ~= nil then
        mp.observe_property("fullscreen", "bool", on_fs_change)
    end
end

mp.observe_property("vo-configured", "bool", on_focused)
