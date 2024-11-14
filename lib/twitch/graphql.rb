require 'net/https'
require 'json'

require 'twitch/constants'
require 'twitch/error'

module Twitch
  module Graphql
    include Twitch::Constants

    def request_live_access_token(options)
      result = make_gql_request({
        "operationName": "PlaybackAccessToken_Template",
        "query": "query PlaybackAccessToken_Template($login: String!, $isLive: Boolean!, $vodID: ID!, $isVod: Boolean!, $playerType: String!) {  streamPlaybackAccessToken(channelName: $login, params: {platform: \"web\", playerBackend: \"mediaplayer\", playerType: $playerType}) @include(if: $isLive) {    value    signature    __typename  }  videoPlaybackAccessToken(id: $vodID, params: {platform: \"web\", playerBackend: \"mediaplayer\", playerType: $playerType}) @include(if: $isVod) {    value    signature    __typename  }}",
        "variables": {
          "isLive": true,
          "login": options[:broadcaster],
          "isVod": false,
          "vodID": "",
          "playerType": "site"
        }
      })

      raise Twitch::Error.new(result["errors"][0]["message"]) if result["errors"]

      result["data"]["streamPlaybackAccessToken"]
    end

    def request_vod_access_token(options)
      result = make_gql_request({
        "operationName": "PlaybackAccessToken_Template",
        "query": "query PlaybackAccessToken_Template($login: String!, $isLive: Boolean!, $vodID: ID!, $isVod: Boolean!, $playerType: String!) {  streamPlaybackAccessToken(channelName: $login, params: {platform: \"web\", playerBackend: \"mediaplayer\", playerType: $playerType}) @include(if: $isLive) {    value    signature    __typename  }  videoPlaybackAccessToken(id: $vodID, params: {platform: \"web\", playerBackend: \"mediaplayer\", playerType: $playerType}) @include(if: $isVod) {    value    signature    __typename  }}",
        "variables": {
          "isLive": false,
          "login": "",
          "isVod": true,
          "vodID": options[:video_id],
          "playerType": "site"
        }
      })

      raise Twitch::Error.new(result["errors"][0]["message"]) if result["errors"]

      result["data"]["videoPlaybackAccessToken"]
    end

    def request_broadcasts(options)
      result = make_gql_request({
          "operationName": "FilterableVideoTower_Videos",
          "variables": {
              "includePreviewBlur": false,
              "limit": options[:limit],
              "channelOwnerLogin": options[:broadcaster],
              "broadcastType": "ARCHIVE",
              "videoSort": "TIME"
          },
          "extensions": {
              "persistedQuery": {
                  "version": 1,
                  "sha256Hash": "08eed732ca804e536f9262c6ce87e0e15f07d6d3c047e8e5d7a461afd5a66a00"
              }
          }
      })

      raise Twitch::Error.new("Could not get result") if not result
      raise Twitch::Error.new(result["errors"][0]["message"]) if result["errors"]
      raise Twitch::Error.new("Streamer %s not found" % options[:broadcaster]) if not result["data"]["user"]

      videos_meta = result["data"]["user"]["videos"]["edges"]

      videos_meta.map do |meta|
        node = meta["node"]

        {
          "published_at": node["publishedAt"],
          "title": node["title"],
          "id": node["id"]
        }
      end
    end

    def request_stream_data(options)
      result = make_gql_request({
          "operationName": "ChannelRoot_Channel",
          "variables": {
              "currentChannelLogin": options[:broadcaster],
              "includeChanlets": true
          },
          "extensions": {
              "persistedQuery": {
                  "version": 1,
                  "sha256Hash": "ce18f2832d12cabcfee42f0c72001dfa1a5ed4a84931ead7b526245994810284"
              }
          }
      })

      raise Twitch::Error.new(result["errors"][0]["message"]) if result["errors"]

      display_name = result["data"]["user"]["displayName"]
      stream_details = result["data"]["user"]["stream"]

      # In `bin/twitch`, we don't call this method until we have already requested
      # the m3u8, and so in theory the streamer should be live by this point and should
      # have stream details. However, there seems to be some cases when the streamer
      # has an m3u8 but no stream details, so we return if it is nil to prevent errors
      # below
      return unless stream_details

      {
        "id": stream_details["id"],
        "title": stream_details["title"],
        "current_game": stream_details.dig("game", "displayName"),
        "viewers": stream_details["viewersCount"],
        "display_name": display_name
      }
    end

    private

    def make_gql_request(query)
      uri = URI.parse(GRAPHQL_API_URL)

      https = Net::HTTP.new(uri.host, 443)
      https.use_ssl = true

      # We know that we only have a fragment here, so just include it. This won't work if
      # we have a query as well
      req = Net::HTTP::Post.new(uri.path)
      req.body = JSON.generate([query])
      req['Client-Id'] = CLIENT_ID

      resp = https.request(req)

      if resp.code != '200'
        raise Twitch::Error.new("Unexpected status code %s: %s" % [resp.code, resp.message])
      end

      # Assume `query` above only contains one object
      JSON.parse(resp.body)[0]
    end
  end
end
