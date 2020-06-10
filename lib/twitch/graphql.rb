require 'net/https'
require 'json'

require 'twitch/constants'

module Twitch
  module Graphql
    include Twitch::Constants

    def request_broadcasts(options)
      result = make_gql_request({
          "operationName": "FilterableVideoTower_Videos",
          "variables": {
              "limit": options[:limit],
              "channelOwnerLogin": options[:broadcaster],
              "broadcastType": "ARCHIVE",
              "videoSort": "TIME"
          },
          "extensions": {
              "persistedQuery": {
                  "version": 1,
                  "sha256Hash": "a937f1d22e269e39a03b509f65a7490f9fc247d7f83d6ac1421523e3b68042cb"
              }
          }
      })

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
        "current_game": stream_details["game"]["displayName"],
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

      # Assume `query` above only contains one object
      JSON.parse(resp.body)[0]
    end
  end
end