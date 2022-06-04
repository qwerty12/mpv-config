"""
This Python script is responsible for executing the web requests.
Each request is dictated by the flag received.

TODO: Add the ability to refresh token
"""
import re
import sys
import os
import json
from time import sleep

import requests
from datetime import date, datetime, timezone

now = datetime.now(timezone.utc).isoformat() + "Z"

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
    if 'client_id' not in configs or 'client_secret' not in configs or len(configs['client_id']) != 64 or len(configs['client_secret']) != 64:
        sys.exit(10)

    if 'access_token' not in configs or len(configs['access_token']) != 64:
        sys.exit(11)

    # TODO Refresh token
    sys.exit(0)


def code(flags, configs):
    """ Generate the code """
    res = requests.post('https://api.trakt.tv/oauth/device/code', json={'client_id': configs['client_id']})

    configs['device_code'] = res.json()['device_code']
    write_json(configs)

    print(res.json()['user_code'], end='')


def auth(flags, configs):
    """ Authenticate """
    res = requests.post('https://api.trakt.tv/oauth/device/token', json={
        'client_id': configs['client_id'],
        'client_secret': configs['client_secret'],
        'code': configs['device_code']
    })

    res_json = res.json()

    if 'access_token' in res_json:
        # Success
        configs['access_token'] = res_json['access_token']
        configs['refresh_token'] = res_json['refresh_token']
        del configs['device_code']
        configs['today'] = str(date.today())

        # Get the user's slug
        res = requests.get('https://api.trakt.tv/users/settings', headers={
            'trakt-api-key': configs['client_id'],
            'Authorization': 'Bearer ' + configs['access_token'],
            'trakt-api-version': '2'
        })

        if res.status_code != 200:
            sys.exit(-1)

        configs['user_slug'] = res.json()['user']['ids']['slug']
        write_json(configs)
        sys.exit(0)

    sys.exit(-1)


def query(flags, configs):
    """ Searches Trakt.tv for the content that it's being watched """
    media = flags[2]

    # Check if it is an episode (Show name followed by the season an episode)
    infos = re.search(r'(.+)S([0-9]+).*E([0-9]+).*', media, re.IGNORECASE)

    if infos is not None and len(infos.groups()) == 3:
        name = infos.group(1)
        season_id = infos.group(2)
        ep_id = infos.group(3)
        __query_search_ep(name, season_id, ep_id, configs)

    # It's not an episode, then it must be a movie (Movie name followed by the year)
    infos = re.search(r'(.+)([1-9][0-9]{3}).*', media, re.IGNORECASE)

    if infos is not None and len(infos.groups()) == 2:
        movie_year = infos.group(2)
        __query_movie(infos.group(1), movie_year, configs)

    # Neither of the patterns matched, try using guessit
    import guessit
    guess = guessit.guessit(media)
    if guess['type'] == "episode":
        __query_search_ep(guess['title'], str(guess['season']), str(guess['episode']), configs)
    elif guess['type'] == "movie":
        year = guess.get('year')
        if year is not None: year = str(year)
        __query_movie(guess['title'], year, configs)

    # Neither of the patterns matched, try using the whole name (Name followed by the file extension)
    # infos = re.search(r'(.+)\.[0-9A-Za-z]{3}', media, re.IGNORECASE)
    # __query_whatever(infos.group(1), configs)


def __query_search_ep(name, season, ep, configs):
    """ Get the episode """
    res = requests.get(
        'https://api.trakt.tv/search/show',
        params={'query': clean_name(name)},
        headers={'trakt-api-key': configs['client_id'], 'trakt-api-version': '2'}
    )

    if res.status_code != 200:
        sys.exit(-1)

    if len(res.json()) == 0:
        sys.exit(14)

    # Found it!
    show_title = res.json()[0]['show']['title']
    show_slug = res.json()[0]['show']['ids']['slug']
    # show_trakt_id = res.json()[0]['show']['ids']['trakt']

    print(show_title + ' S' + season + 'E' + ep, end='')

    # Get the episode
    res = requests.get(
        'https://api.trakt.tv/shows/' + show_slug + '/seasons/' + season + '/episodes/' + ep,
        headers={'trakt-api-key': configs['client_id'], 'trakt-api-version': '2'}
    )

    if res.status_code != 200:
        sys.exit(-1)

    checkin(configs, {
        'episodes': [
            {
                "watched_at": now,
                "ids": res.json()["ids"]
            }
        ]
    })


def __query_movie(movie, year, configs):
    """ Get the movie """
    res = requests.get(
        'https://api.trakt.tv/search/movie',
        params={'query': clean_name(movie)},
        headers={'trakt-api-key': configs['client_id'], 'trakt-api-version': '2'}
    )

    if res.status_code != 200:
        sys.exit(-1)

    show_title = res.json()[0]['movie']['title']
    show_slug = res.json()[0]['movie']['ids']['slug']
    show_trakt_id = res.json()[0]['movie']['ids']['trakt']

    if len(res.json()) == 0:
        sys.exit(14)

    # Find the movie by year
    if year is not None:
        for obj in res.json():
            if obj['movie']['year'] == int(year):
                show_title = obj['movie']['title']
                show_slug = obj['movie']['ids']['slug']
                show_trakt_id = obj['movie']['ids']['trakt']

    print(show_title, end='')

    checkin(configs, {
        'movies': [
            {
                "watched_at": now,
                "ids": {'trakt': show_trakt_id}
            }
        ]
    })

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


def checkin(configs, body):
    res = requests.post(
        'https://api.trakt.tv/sync/history',
        headers={
            'trakt-api-key': configs['client_id'],
            'trakt-api-version': '2',
            'Authorization': 'Bearer ' + configs['access_token'],
            'Content-Type': 'application/json'
        },
        json=body
    )

    if res.status_code != 201:
        sys.exit(-1)
    sys.exit(0)



"""
MAIN
"""


def main():
    # Get the configs
    try:
        f = open(os.path.dirname(os.path.abspath(__file__)) + '/config.json', 'r')
        data = json.load(f)
        f.close()
    except:
        sys.exit(10)

    # Choose what to do
    switch = {
        '--hello': hello,
        '--query': query,
        '--code': code,
        '--auth': auth
    }

    if sys.argv[1] in switch:
        switch[sys.argv[1]](sys.argv, data)
    else:
        sys.exit(-1)


if __name__ == "__main__":
    main()
