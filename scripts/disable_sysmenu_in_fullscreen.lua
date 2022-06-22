local bit = require("bit")
local ffi = require("ffi")
ffi.cdef [[
void* __stdcall FindWindowExA(void *hWndParent, void *hWndChildAfter, const char *lpszClass, const char *lpszWindow);
unsigned int __stdcall GetWindowThreadProcessId(void *hWnd, unsigned int *lpdwProcessId);
unsigned long __stdcall GetWindowLongPtrW(void *hWnd, int nIndex);
int64_t __stdcall SetWindowLongPtrW(void *hWnd, int nIndex, unsigned long dwNewLong);
void __stdcall Sleep(unsigned long dwMilliseconds);
]]

local GWL_STYLE = -16
local WS_SYSMENU = 0x00080000

local mpv_hwnd
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

local function on_fs_change(name, value)
    if not value then return end

    local style
    for i = 1, 10 do
        ffi.C.Sleep(100)
        style = ffi.C.GetWindowLongPtrW(mpv_hwnd, GWL_STYLE)
        if bit.band(style, WS_SYSMENU) == WS_SYSMENU then break end
    end
    if mp.get_property_bool(name) then
        ffi.C.SetWindowLongPtrW(mpv_hwnd, GWL_STYLE, bit.band(style, bit.bnot(WS_SYSMENU)))
    end
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
