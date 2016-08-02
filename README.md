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

When choosing the `vod` option, you will be presented with the 10 latest VODs, with which you can choose by number and watch like you would a live stream.

## Notes

This gem uses private APIs and may break at any time. This was built before Twitch was using HLS for all of their streams and was still using Flash, which meant that it was only usable on Chrome (as I didn't have Flash installed on Safari) and meant my laptop would work much harder. This gem bypasses that by playing the same content in QuickTime. It's not as useful now, as Twitch has switched over mainly to HLS streaming, but it's still convenient from a OS standpoint as it runs in a separate process from the browser (meaning you can command-tab between browser and Quicktime).

If you use this gem, consider subscribing or donating to the streamer as this bypasses the Twitch player and the ads that are delivered with it! Show them some financial support!

## License

MIT
