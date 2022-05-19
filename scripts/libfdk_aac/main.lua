local ffi = require 'ffi'
local bit = require 'bit'
ffi.cdef[[
int __stdcall MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags, const char *lpMultiByteStr, int cbMultiByte, wchar_t *lpWideCharStr, int cchWideChar);
int _wputenv_s(const wchar_t *name, const wchar_t *value);
unsigned long __stdcall GetFileAttributesW(const wchar_t* lpFileName);
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

local function FileExistsW(FileName)
    local dwAttrib = ffi.C.GetFileAttributesW(FileName)

    return dwAttrib ~= INVALID_FILE_ATTRIBUTES and bit.band(dwAttrib, FILE_ATTRIBUTE_DIRECTORY) ~= FILE_ATTRIBUTE_DIRECTORY
end

-- can safely assume Windows, so avoid mp.utils.join_path
local fdk_dll = MultiByteToWideChar(mp.get_script_directory():gsub("/", "\\") .. "\\libfdk-aac-2.dll")
if FileExistsW(fdk_dll) and ffi.C._wputenv_s(MultiByteToWideChar("__MP_FDKAAC_PATH"), fdk_dll) == 0 then
    mp.set_property("ad", "libfdk_aac")
end