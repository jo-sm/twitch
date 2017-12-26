module Twitch
  module Constants
    CLIENT_ID = 'jzkbprff40iqj646a697cyrvl0zt2m6'

    # URLs
    M3U8_URL_LIVE = "https://usher.ttvnw.net/api/channel/hls/%{broadcaster}.m3u8"
    M3U8_URL_VOD = "https://usher.ttvnw.net/vod/%{video_id}.m3u8"

    VODS_API_URL = "https://api.twitch.tv/kraken/channels/%{broadcaster}/videos"

    TOKEN_URL_LIVE = "https://api.twitch.tv/api/channels/%{broadcaster}/access_token"
    TOKEN_URL_VOD = "https://api.twitch.tv/api/vods/%{video_id}/access_token"
  end
end