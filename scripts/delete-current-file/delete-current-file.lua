
--[[

    https://github.com/stax76/mpv-scripts

    This script instantly deletes the file that is currently playing
    via keyboard shortcut, the file is moved to the recycle bin and
    removed from the playlist.

    On Linux the app trash-cli must be installed first.

    Usage:
    Add bindings to input.conf:

    # delete directly
    KP0 script-message-to delete_current_file delete-file

    # delete with confirmation
    KP0 script-message-to delete_current_file delete-file KP1 "Press 1 to delete file"

    Press KP0 to initiate the delete operation,
    the script will ask to confirm by pressing KP1.
    You may customize the the init and confirm key and the confirm message.
    Confirm key and confirm message are optional.

    Similar scripts:
    https://github.com/zenyd/mpv-scripts#delete-file

]]--

local file_to_delete = ""
local key_bindings = {}
local confirm_key = nil

function is_protocol(path)
    return type(path) == 'string' and (path:match('^%a[%a%d_-]+://'))
end

function delete_file()
    if mp.get_property_number("playlist-count") == 1 then
        mp.command("script-binding uosc/delete-file-quit")
    else
        mp.command("script-binding uosc/delete-file-next")
    end
end

function handle_confirm_key()
    local path = mp.get_property("path")

    if file_to_delete == path then
        mp.commandv("show-text", "")
        delete_file()
        remove_bindings()
        file_to_delete = ""
    end
end

function cleanup()
    remove_bindings()
    file_to_delete = ""
    mp.commandv("show-text", "")
end

function get_bindings()
    return {
        { confirm_key,  handle_confirm_key },
    }
end

function add_bindings()
    if #key_bindings > 0 then
        return
    end

    local script_name = mp.get_script_name()

    for _, bind in ipairs(get_bindings()) do
        local name = script_name .. "_key_" .. (#key_bindings + 1)
        key_bindings[#key_bindings + 1] = name
        mp.add_forced_key_binding(bind[1], name, bind[2])
    end
end

function remove_bindings()
    if #key_bindings == 0 then
        return
    end

    for _, name in ipairs(key_bindings) do
        mp.remove_key_binding(name)
    end

    key_bindings = {}
end

function client_message(event)
    local path = mp.get_property("path")
    if is_protocol(path) then return end

    if event.args[1] == "delete-file" and #event.args == 1 then
        delete_file()
    elseif event.args[1] == "delete-file" and #event.args == 3 and #key_bindings == 0 then
        confirm_key = event.args[2]
        mp.add_timeout(5, cleanup)
        add_bindings()
        file_to_delete = path
        local msg = mp.command_native({"expand-text", event.args[3]})
        mp.commandv("show-text", msg, "5000")
    end
end

mp.register_event("client-message", client_message)
