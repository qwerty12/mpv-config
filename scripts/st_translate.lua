local function trim(str)
    -- https://stackoverflow.com/a/48328232
    if str == '' then
        return str
    else
        local startPos = 1
        local endPos   = #str

        while (startPos < endPos and str:byte(startPos) <= 32) do
            startPos = startPos + 1
        end

        if startPos >= endPos then
            return ''
        else
            while (endPos > 0 and str:byte(endPos) <= 32) do
                endPos = endPos - 1
            end

            return str:sub(startPos, endPos)
        end
    end
end

-- URL encode a string. https://github.com/stuartpb/tvtropes-lua/blob/master/urlencode.lua
local function urlencode(str)
    --Ensure all newlines are in CRLF form
    str = string.gsub(str, "\r?\n", "\r\n")

    --Percent-encode all non-unreserved characters
    --as per RFC 3986, Section 2.3
    --(except for space, which gets plus-encoded)
    str = string.gsub(str, "([^%w%-%.%_%~ ])",
        function(c) return string.format("%%%02X", string.byte(c)) end)

    --Convert spaces to plus signs
    str = string.gsub(str, " ", "+")

    return str
end

local function gt()
    local sub_text = mp.get_property("sub-text")
    if not sub_text then return end
    sub_text = trim(sub_text)
    if sub_text == '' then return end

    sub_text = sub_text:gsub("\r", "")
    sub_text = sub_text:gsub("\n\n", "\n")

    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        detach = true,
        args = { "C:\\Program Files\\Firefox Developer Edition\\firefox.exe", "https://translate.google.com/#auto/en/" .. urlencode(sub_text) } -- "https://www.deepl.com/translator#auto/en/"
    })
end

mp.add_key_binding(nil, "gt", gt)
