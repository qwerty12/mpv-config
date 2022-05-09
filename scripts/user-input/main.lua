local msgs = {"request-user-input", "cancel-user-input"}

local function load()
    for i, msg in ipairs(msgs) do
        mp.unregister_script_message(msg)
    end
    require('user-input')
end

for i, msg in ipairs(msgs) do
    local function lazy_load(...)
        load()
        mp.commandv("script-message-to", "user_input", msg, unpack({...}))
    end
    mp.register_script_message(msg, lazy_load)
end