local ffi = require 'ffi'
local bit = require 'bit'
ffi.cdef[[
int __stdcall MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags, const char *lpMultiByteStr, int cbMultiByte, wchar_t *lpWideCharStr, int cchWideChar);
int _wputenv_s(const wchar_t *name, const wchar_t *value);
unsigned long __stdcall GetFileAttributesW(const wchar_t *lpFileName);
bool CreateDirectoryW(const wchar_t *lpPathName, void *lpSecurityAttributes);
]]
local INVALID_FILE_ATTRIBUTES = 0xffffffff
local FILE_ATTRIBUTE_DIRECTORY = 0x00000010

local function MultiByteToWideChar(MultiByteStr)
    if MultiByteStr then
        local utf16_len = ffi.C.MultiByteToWideChar(65001, 0, MultiByteStr, -1, nil, 0)
        if utf16_len > 0 then
            --utf16_len = utf16_len + 1
            local utf16_str = ffi.new("wchar_t[?]", utf16_len)
            if ffi.C.MultiByteToWideChar(65001, 0, MultiByteStr, -1, utf16_str, utf16_len) > 0 then
                return utf16_str
            end
        end
    end

    return nil
end

local function FolderExistsW(FileName)
    local dwAttrib = ffi.C.GetFileAttributesW(FileName)
    return dwAttrib ~= INVALID_FILE_ATTRIBUTES and bit.band(dwAttrib, FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY
end

ffi.C._wputenv_s(MultiByteToWideChar("CLINK_NOAUTORUN"), ffi.new("wchar_t[1]", string.byte("1")))
local new_temp = MultiByteToWideChar("D:\\.mpv_temp")
if FolderExistsW(new_temp) or ffi.C.CreateDirectoryW(new_temp, nil) then
    ffi.C._wputenv_s(MultiByteToWideChar("TEMP"), new_temp)
    ffi.C._wputenv_s(MultiByteToWideChar("TMP"), new_temp)
end