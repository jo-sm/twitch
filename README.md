# Twitch

Twitch is a ruby gem that lets you watch Twitch streams and VODs on your Mac through Quicktime. 

## Installation

It is purposefully not available on rubygems.org. You will need to download the source using git, build it into a gem, and install it manually:

```
> git clone https://github.com/jo-sm/twitch
> cd twitch
> gem build twitch.gemspec
> gem install twitch-<VERSION>.gem
```

## Usage

You can run the global `twitch` command from the command line, which takes two arguments: mode, and broadcaster:

```
> twitch live frankerz
> twitch vod frankerz
```

You can supply five flags: `--limit`, which is the number of streams requested to the API, defaulted to 30; `--player`, which is the player that is used to play the stream, defaulted to QuickTime Player; `--resolution` and `--bitrate`, which select the highest available resolution or bitrate for this stream; and `--always`, which always skips the quality menu and plays the highest resolution/bitrate. You can see all these flags with the `--help` flag.

An example usage:

```
> twitch live frankerz --limit 20 --player VLC
```

I generally use QuickTime Player, because it handles videos with more power efficiency than other players, but there are some cases where it cannot parse a playlist. When I encounter an issue I use VLC or mplayer.

## Tab Completion

If you'd like to enable tab completion for the keywords (vod, live) and the broadcasters you've previously watched, you can add one of the following autocompletion scripts.

### Zsh

If you have Zsh completions setup, you can add the following completion as a file in your completions directory, most likely `~/.zcompletions`:

```
#compdef twitch
typeset -A opt_args

local streamers=( $(ruby -e "require 'json'; puts JSON.load(open(File.join(Dir.home, '.twitch', 'config'), 'r').read)[\"broadcasters\"].join ' '") )

_arguments -C \
  '1:cmd:(live vod)' \
  '2:streamers:($streamers)'
```

### Bash

Put the following in your `~/.bash_profile`:

```
_twitch_tab_complete() {
  COMPREPLY=()
  completions=()

  local current_word="${COMP_WORDS[COMP_CWORD]}"
  local previous_word="${COMP_WORDS[COMP_CWORD-1]}"
  local words_length="${#COMP_WORDS[@]}"

  if [[ "$previous_word" =~ ^(live|vod)$ ]]; then
    if [ -s ~/.twitch/config ]; then
      completions=( $(ruby -e "require 'json'; puts JSON.load(open(File.join(Dir.home, '.twitch', 'config'), 'r').read)[\"broadcasters\"].join ' '") )
    fi
  elif [ "3" -gt "${words_length}" ]; then
    if [[ "$current_word" == l* ]]; then
      completions=("live")
    elif [[ "$current_word" == v* ]]; then
      completions=("vod")
    fi
  fi

  COMPREPLY=( $(compgen -W "${completions[*]}" -- "$current_word") )
}

complete -F _twitch_tab_complete twitch
```

## Notes

This gem uses private APIs and may break at any time. I do use the gem regularly and do update it, but if something is broken, please be patient. The main reason that I wrote this was that before Twitch switched to HLS streaming, it used a very resource intensive Flash player, but allowed HLS streaming for specific platforms like the iOS app. All of the web players use HLS by default now, but I still prefer to watch in a different window rather than in the browser.

If you use this gem, consider subscribing or donating to the streamer as this bypasses the Twitch player and the ads that are delivered with it. Show them some financial support!

## License

MIT
