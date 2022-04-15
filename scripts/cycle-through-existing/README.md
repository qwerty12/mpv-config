# mpv-cycle-through-existing

This is a short Lua script for [mpv](https://github.com/mpv-player/mpv)
that allows cycling through **existing** video, audio and subtitle tracks,
skipping the "none" option. 

### Usage

Save `cycle-through-existing.lua` in `~/.config/.mpv/scripts/` (Linux and macOS)
or `%AppData%\mpv\scripts\` (Windows). Edit your `input.conf` file to include
the shortcuts for `script-binding cycle_{video,audio,sub,secondary_sub}_{up,down}`.
Example:
```
_     script-binding cycle_video_up
SHARP script-binding cycle_audio_up
j     script-binding cycle_sub_up
J     script-binding cycle_sub_down
```
