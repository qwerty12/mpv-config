--[[
Copyright 2020 Vinícius B. Matos

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]


local state = {
    selected = {V = 0, A = 0, S = 0, s = 0},
    total = {V = 0, A = 0, S = 0}
}

local function update_selected_tracks()
    state.selected = {
        V = mp.get_property_native('video') or 0,
        A = mp.get_property_native('audio') or 0,
        S = mp.get_property_native('sub') or 0,
        s = mp.get_property_native('secondary-sid') or 0,
    }
end

local function update_tracks()
    all_tracks = mp.get_property_native('track-list', {})
    state.total = {V = 0, A = 0, S = 0}
    for i = 1, #all_tracks do
        local track = all_tracks[i]
        if track.type == 'video' then
            state.total.V = math.max(state.total.V, track.id)
        elseif track.type == 'audio' then
            state.total.A = math.max(state.total.A, track.id)
        elseif track.type == 'sub' then
            state.total.S = math.max(state.total.S, track.id)
        end
    end
    update_selected_tracks()
end

local function change(x, step) -- 'V', 'A', 'S' or 's'; -1 or +1
    local keys = {A='audio', V='video', S='sub', s='secondary-sid'}
    local key = keys[x]
    update_selected_tracks()
    local old = state.selected[x] or 0
    local current = old + step
    local total = state.total[string.upper(x)]
    if current <= 0 then current = total end
    if current > total then current = math.min(1, total) end
    mp.command('set ' .. key .. ' ' .. current)
end

local function _up(x)
    return function () change(x,  1) end
end

local function _down(x)
    return function () change(x, -1) end
end

mp.register_event('start-file', update_tracks)
mp.register_event('file-loaded', update_tracks)
mp.observe_property('tracks-changed', 'native', update_tracks)

mp.add_key_binding(nil, 'cycle_video_up',         _up('V'))
mp.add_key_binding(nil, 'cycle_audio_up',         _up('A'))
mp.add_key_binding(nil, 'cycle_sub_up',           _up('S'))
mp.add_key_binding(nil, 'cycle_secondary_sub_up', _up('s'))

mp.add_key_binding(nil, 'cycle_video_down',         _down('V'))
mp.add_key_binding(nil, 'cycle_audio_down',         _down('A'))
mp.add_key_binding(nil, 'cycle_sub_down',           _down('S'))
mp.add_key_binding(nil, 'cycle_secondary_sub_down', _down('s'))

--[[
EXAMPLE (input.conf):
#####################

_     script-binding cycle_video_up
SHARP script-binding cycle_audio_up
j     script-binding cycle_sub_up
J     script-binding cycle_sub_down

--]]
