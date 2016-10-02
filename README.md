# Twitch

Twitch is a ruby gem that lets you watch Twitch streams and VODs on your Mac through Quicktime. 

## Installation

You will need to download the source using git, build it into a gem, and install it manually:

```
> git clone https://github.com/jo-sm/twitch
> cd twitch
> gem build twitch.gemspec
> gem install twitch-0.0.3.gem
```

## Usage

You can run the global `twitch` command from the command line, which takes two arguments: mode, and broadcaster:

```
> twitch live frankerz
> twitch vod frankerz
```

When choosing the `vod` option, you will be presented with the 10 latest VODs, with which you can choose by number and watch like you would a live stream.

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
    if [ -s ~/.twitch/broadcaster_cache ]; then
      completions=( $(ruby -e "require 'json'; puts JSON.load(open(File.join(Dir.home, '.twitch', 'broadcaster_cache'), 'r').read).join ' '") )
    fi
  elif [ "3" -gt "${words_length}" ]; then
    if [[ "$current_word" == l* ]]; then
      completions=("live")
    elif [[ "$current_word" == v* ]]; then
      completions=("vod")
    fi
  fi

  COMPREPLY=( $(compgen -W "$completions" -- "$word") )
}

complete -F _twitch_tab_complete twitch
```

## Notes

This gem uses private APIs and may break at any time. This was built before Twitch was using HLS for all of their streams and was still using Flash, which meant that it was only usable on Chrome (as I didn't have Flash installed on Safari) and meant my laptop would work much harder. This gem bypasses that by playing the same content in QuickTime. It's not as useful now, as Twitch has switched over mainly to HLS streaming, but it's still convenient from a OS standpoint as it runs in a separate process from the browser (meaning you can command-tab between browser and Quicktime).

If you use this gem, consider subscribing or donating to the streamer as this bypasses the Twitch player and the ads that are delivered with it! Show them some financial support!

## License

MIT
