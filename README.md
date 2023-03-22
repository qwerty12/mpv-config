Config for [mpv](https://mpv.io/). I use this on Windows with [my modified nightly `mpv` builds](https://github.com/qwerty12/mpv-winbuild/) (a Scoop manifest can be found in [my bucket](https://github.com/qwerty12/scoop-alts)).

[uosc](https://github.com/tomasklaen/uosc) is used to provide the OSC.

### Notes

* **IMPORTANT**: Most scripts here are modified - some even have functionality removed. You might prefer to use the original versions.

    * Use this repo as a template, not as-is.

* I do not watch anime.

* My system has a poor iGPU but lots of RAM:

    * I request HW decoding via Direct3D 11 explicitly

    * I use `gpu-hq` except for anything above 1080{p/i}

    * For content close to your display's resolution, [autoscaling.lua](https://github.com/kevinlekiller/mpv_scripts/blob/master/autoscaling/auto_scaling.lua) disables scaling

    * Cache amounts are rather high in mpv.conf, and for 4k content, `hwdec-extra-frames` is set to 64
    
* mpv's logging messages are kept to a minimum if not launched from a Command Prompt. comment out `msg-level` in mpv.conf to see scripts'/mpv errors in the mpv console

* Files without subtitles in certain folders with certain matching characters in their filenames get sped up to 1.25x automatically - see speedtoggle.lua

* Downmixing of 7.1/5.1 channel audio is done with sofalizer/ClubFritz6

    * You might want to set your output device to sample at 48000Hz in the Control Panel if using CF6

        * ref: ["I noticed the ClubFritz4 downsamples to 44100Hz, while ClubFritz6.sofa is 48000Hz, my DAC doesn't support 44100Hz, so with ClubFritz4 it's being upsampled to back to 48000Hz (by pipewire or pulseaudio I'm guessing). So using ClubFritz6 avoids that second resampling."](https://old.reddit.com/r/mpv/comments/11cr5u9/is_it_possible_to_use_the_headphone_filter/jc7rqn6/)

* The Cascadia Mono font should be present on your system. I think it comes with Windows 11 or the new Windows Terminal or both.

* The forward subtitle cycling key, `s`, will bring up uosc's subtitle selection menu instead if 10 or more subtitle tracks are present

* po5's chapterskip script is present and is configured to skip certain named chapters at the beginning of videos if present

* You should have `cacert` globally installed with [Scoop](https://scoop.sh) or comment out `tls-ca-file` and `tls-verify` in mpv.conf

* mpv.conf and script-opts\autosubsync.conf, at the very least, hardcode paths specific to my system, which you should change for correct operation

* Where possible, `D:\.mpv_temp` is used to store temporary files created by mpv or one of its scripts. This might cause breakage on your system if the folder doesn't exist.

### Credits

For the scripts, it should be obvious where they're from, so I'll avoid listing them again. Configurations were copied from the following places:

https://github.com/dexeonify/mpv-config/

https://github.com/CogentRedTester/my-mpv-settings/

https://github.com/po5/mpv-config/

https://github.com/AN3223/dotfiles/

https://github.com/he2a/mpv-config/

https://github.com/DrPleaseRespect/DrPleaseRespect-MPV-Config/

https://github.com/deus0ww/mpv-conf/

https://codeberg.org/kevincs/config_files/src/branch/main/mpv
