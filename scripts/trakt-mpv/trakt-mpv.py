"""
This Python script is responsible for executing the web requests.
Each request is dictated by the flag received.

TODO: Add the ability to refresh token
"""
import re
import sys
import os
import json

dont_add_if_already_watched = True

"""
HELPERS
"""


def write_json(data):
    with open(os.path.dirname(os.path.abspath(__file__)) + '/config.json', 'w') as outfile:
        json.dump(data, outfile, indent=4)


def clean_name(name):
    """ Removes special characters and the year """
    result = name.replace('.', ' ')
    result = result.replace('_', ' ')
    result = re.sub(r'\(.*\)|-|\[.*\]', '', result)
    result = re.sub(r'([1-9][0-9]{3})', '', result)

    return result


"""
REQUESTS
"""


def hello(flags, configs):
    """
    This function is called as an initial setup. It creates a 15 second delay before responding, so no scrobble happens
    by mistake.
     - Checks if the client_id and client_secret have already been set (if not, exits as 10)
     - Checks if the access_token has already been set (if not, exits as 11)
     - Checks if there is a need to refresh the token (automaticly refreshes and exits as 0)
    """
    try:
        if len(configs['client_id']) != 64 or len(configs['client_secret']) != 64:
            sys.exit(10)
    except KeyError:
        sys.exit(10)

    if 'access_token' not in configs or len(configs['access_token']) != 64:
        sys.exit(11)

    # TODO Refresh token
    sys.exit(0)


def code(flags, configs):
    """ Generate the code """
    from requests import post
    res = post('https://api.trakt.tv/oauth/device/code', json={'client_id': configs['client_id']})

    configs['device_code'] = res.json()['device_code']
    write_json(configs)

    print(res.json()['user_code'], end='')


def auth(flags, configs):
    """ Authenticate """
    from requests import post, get
    res = post('https://api.trakt.tv/oauth/device/token', json={
        'client_id': configs['client_id'],
        'client_secret': configs['client_secret'],
        'code': configs['device_code']
    })

    res_json = res.json()

    if 'access_token' in res_json:
        from datetime import date
        # Success
        configs['access_token'] = res_json['access_token']
        configs['refresh_token'] = res_json['refresh_token']
        del configs['device_code']
        configs['today'] = str(date.today())

        # Get the user's slug
        res = get('https://api.trakt.tv/users/settings', headers={
            'trakt-api-key': configs['client_id'],
            'Authorization': 'Bearer ' + configs['access_token'],
            'trakt-api-version': '2'
        })

        if res.status_code != 200:
            res.raise_for_status()

        configs['user_slug'] = res.json()['user']['ids']['slug']
        write_json(configs)
        sys.exit(0)

    sys.exit(-1)


def query(flags, configs):
    """ Searches Trakt.tv for the content that it's being watched """
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat() + "Z"
    from requests import Session

    media = flags[2]
    session = Session()
    session.headers.update({
        'Accept-Encoding': 'gzip',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + configs['access_token'],
        'trakt-api-version': '2',
        'trakt-api-key': configs['client_id']
    })

    # Check if it is an episode (Show name followed by the season an episode)
    infos = re.search(r'(.+)S([0-9]+).*E([0-9]+).*', media, re.IGNORECASE)

    if infos is not None and len(infos.groups()) == 3:
        name = infos.group(1)
        season_id = infos.group(2)
        ep_id = infos.group(3)
        __query_search_ep(name, season_id, ep_id, session, now)

    # It's not an episode, then it must be a movie (Movie name followed by the year)
    infos = re.search(r'(.+)([1-9][0-9]{3}).*', media, re.IGNORECASE)

    if infos is not None and len(infos.groups()) == 2:
        movie_year = infos.group(2)
        __query_movie(infos.group(1), movie_year, session, now)

    # Neither of the patterns matched, try using guessit
    import guessit
    guess = guessit.guessit(media)
    if guess['type'] == "episode":
        __query_search_ep(guess['title'], str(guess['season']), str(guess['episode']), session, now)
    elif guess['type'] == "movie":
        year = guess.get('year')
        if year is not None: year = str(year)
        __query_movie(guess['title'], year, session, now)

    # Neither of the patterns matched, try using the whole name (Name followed by the file extension)
    # infos = re.search(r'(.+)\.[0-9A-Za-z]{3}', media, re.IGNORECASE)
    # __query_whatever(infos.group(1), configs)


def __query_search_ep(name, season, ep, session, timestamp):
    """ Get the episode """
    res = session.get(
        'https://api.trakt.tv/search/show',
        params={'query': clean_name(name)}
    )

    if res.status_code != 200:
        res.raise_for_status()

    if len(res.json()) == 0:
        sys.exit(14)

    # Found it!
    show_title = res.json()[0]['show']['title']
    show_slug = res.json()[0]['show']['ids']['slug']
    # show_trakt_id = res.json()[0]['show']['ids']['trakt']

    # Get the episode
    res = session.get(
        'https://api.trakt.tv/shows/' + show_slug + '/seasons/' + season + '/episodes/' + ep
    )

    if res.status_code != 200:
        res.raise_for_status()

    ids = res.json()["ids"]

    if dont_add_if_already_watched:
        watched_history = session.get('https://api.trakt.tv/sync/history/episodes/' + str(ids["trakt"]))

        if watched_history.status_code != 200:
            res.raise_for_status()

        if watched_history.json():
            print(f"{show_title} S{season}E{ep} already marked as watched, won't add duplicate", end='')
            sys.exit(0)

    checkin(session, {
        'episodes': [
            {
                "watched_at": timestamp,
                "ids": ids
            }
        ]
    }, f"{show_title} S{season}E{ep} marked as watched")


def __query_movie(movie, year, session, timestamp):
    """ Get the movie """
    res = session.get(
        'https://api.trakt.tv/search/movie',
        params={'query': clean_name(movie)}
    )

    if res.status_code != 200:
        res.raise_for_status()

    show_title = res.json()[0]['movie']['title']
    # show_slug = res.json()[0]['movie']['ids']['slug']
    show_trakt_id = res.json()[0]['movie']['ids']['trakt']

    if len(res.json()) == 0:
        sys.exit(14)

    # Find the movie by year
    if year is not None:
        for obj in res.json():
            if obj['movie']['year'] == int(year):
                show_title = obj['movie']['title']
                # show_slug = obj['movie']['ids']['slug']
                show_trakt_id = obj['movie']['ids']['trakt']

    if dont_add_if_already_watched:
        watched_history = session.get('https://api.trakt.tv/sync/history/movies/' + str(show_trakt_id))

        if watched_history.status_code != 200:
            watched_history.raise_for_status()

        if watched_history.json():
            print(f"{show_title} already marked as watched, won't add duplicate", end='')
            sys.exit(0)

    checkin(session, {
        'movies': [
            {
                "watched_at": timestamp,
                "ids": {'trakt': show_trakt_id}
            }
        ]
    }, f"{show_title} marked as watched")

# def __query_whatever(name, configs):
#     """ Get something purely by the name """
#     res = requests.get(
#         'https://api.trakt.tv/search/movie',
#         params={'query': clean_name(name)},
#         headers={'trakt-api-key': configs['client_id'], 'trakt-api-version': '2'}
#     )

#     if res.status_code != 200:
#         sys.exit(-1)

#     if len(res.json()) == 0:
#         sys.exit(14)

#     # Find the first result
#     show_title = res.json()[0]['movie']['title']
#     show_slug = res.json()[0]['movie']['ids']['slug']
#     show_trakt_id = res.json()[0]['movie']['ids']['trakt']

#     print(show_title, end='')

#     checkin(configs, {
#         'movie': {'ids': {'trakt': show_trakt_id}},
#         'app_version': '2.0'
#     })


def checkin(session, body, msg_on_success=None):
    res = session.post(
        'https://api.trakt.tv/sync/history',
        json=body
    )

    if res.status_code != 201:
        res.raise_for_status()

    if msg_on_success is not None:
        print(msg_on_success, end='')
    sys.exit(0)



"""
MAIN
"""


def main():
    # Choose what to do
    switch = {
        '--hello': hello,
        '--query': query,
        '--code': code,
        '--auth': auth
    }

    if sys.argv[1] in switch:
        # Get the configs
        try:
            with open(os.path.dirname(os.path.abspath(__file__)) + '/config.json', 'r') as f:
                data = json.load(f)
        except:
            sys.exit(10)
        switch[sys.argv[1]](sys.argv, data)
    else:
        sys.exit(-1)


if __name__ == "__main__":
    main()
