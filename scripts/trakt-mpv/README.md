# trakt-mpv

A MPV script that adds movies and show episodes to your Trakt account's watched history without the need for an IPC server.

Forked from [https://github.com/LiTO773/trakt-mpv](https://github.com/LiTO773/trakt-mpv)

## How does it work?

This script is written in both Lua and Python. The Lua part works as a front-end while the Python script is responsible for communicating with Trakt.tv.

This dual-language approach was needed since mpv scripts aren't able to send http requests and/or edit files natively.

## How to install?

### Pre-requisites

In order for this script to work you need to make sure you have Python 3 installed.

After that, make sure you also have the required modules. You can install them like this:

```
pip install --upgrade requests guessit
```

### Installing

The install is pretty simple and can be done with the following steps:

1. Move the **`trakt-mpv`** folder in its entirety to your mpv **`scripts`** folder
2. Create a trakt.tv api. You can do this using: [https://trakt.tv/oauth/applications](https://trakt.tv/oauth/applications). Use `urn:ietf:wg:oauth:2.0:oob` as the redirect URI.
3. Copy your **client_id** and **client_secret** to **trakt-mpv/config_example.json**
4. Rename **trakt-mpv/config_example.json** to **trakt-mpv/config.json**
5. Bind the command `script-message-to trakt_mpv init_trakt_and_set_watched` to a key in your input.conf

Ok the hard part is done, now you'll do the rest in mpv. If you did everything correctly when you open a file and press your designated key the following message will appear: Press *t* to authenticate with Trakt.tv

Press *t* and follow the instructions on the screen. After that you are all set 😀.

## Behaviors

The current behaviors adopted by the plugin are:

 - It will mark the current movie/episode as watched to your Trakt history upon invoking the `init_trakt_and_set_watched` command.
 - Right now there really isn't a good error reporting. So if you find an error I suggest you look at the mpv console.

## License

[MIT](https://choosealicense.com/licenses/mit/)
