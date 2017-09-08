# Twitch

Twitch is a ruby gem that lets you watch Twitch streams and VODs on your Mac through Quicktime. 

## Installation

You will need to download the source using git, build it into a gem, and install it manually:

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

You can also supply two flags, `--limit` and `--player`. By default, the limit is `30` and the player is `QuickTime Player`, but you can change it to suit your specific usage. An example usage:

```
> twitch live frankerz --limit 20 --player VLC
```

Generally, I use QuickTime Player, but there are some cases where it cannot parse a playlist. VLC is more robust, and when I find that QuickTime has issues, I will supply `VLC` to the player flag.

## Tab Completion

If you'd like to enable tab completion for the keywords (vod, live) and the broadcasters you've previously watched, put the following in your `~/.bash_profile`:

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
