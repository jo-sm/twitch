require 'json'
require 'open-uri'

require 'twitch/constants'
require 'twitch/utils'

module Twitch
  module Rest
    include Twitch::Constants
    include Twitch::Utils

    def request_token(type, options)
      token_base = TOKEN_URL_LIVE if type == 'live'
      token_base = TOKEN_URL_VOD if type == 'vod'

      token_url = generate_url(token_base, {
        'params': {
          'broadcaster': options[:broadcaster],
          'video_id': options[:video_id]
        },
        'url_params': {
          'adblock': true,
          'need_https': true,
          'platform': 'web',
          'player_type': 'site'
        }
      })

      raw_token = make_api_request(token_url)
      token = JSON.parse(raw_token, :symbolize_names => true)

      raise "Error: #{token[:message]}" if token[:error]

      token
    end

    def request_m3u8(type, token, options)
      if type == 'live'
        url = generate_url(M3U8_URL_LIVE, {
          'params': {
            'broadcaster': options[:broadcaster]
          },
          'url_params': {
            'token': token[:token],
            'sig': token[:sig],
            'allow_source': true,
            'player_backend': 'html5',
            'baking_bread': true,
            'p': Random.rand(1000000..9999999),
          }
        })
      elsif type == 'vod'
        url = generate_url(M3U8_URL_VOD, {
          'params': {
            'video_id': options[:video_id]
          },
          'url_params': {
            'nauth': token[:token],
            'nauthsig': token[:sig],
            'allow_source': true,
            'allow_spectre': true,
            'p': Random.rand(1000000..9999999),
            'baking_bread': true
          }
        })
      end

      raw_m3u8 = make_api_request url

      parse_m3u8 raw_m3u8
    end

    private

    def make_api_request(raw_uri)
      uri = URI.parse(raw_uri)

      uri.open({
        'Client-ID' => CLIENT_ID
      }).read
    end

    def generate_url(base_url, options)
      url = base_url

      if options[:params]
        url = url % options[:params].map { |k,v| [k, v] }.reduce({}) { |memo, a| memo[a[0]] = a[1]; memo }
      end

      if options[:url_params]
        url = "#{url}?#{URI.encode_www_form(options[:url_params])}"
      end

      url
    end

    def parse_m3u8(raw)
      streams = raw.split("\n")

      skip = false
      sources = []

      streams.each_with_index do |line, i| 
        if skip
          skip = false
          next
        end

        if line.start_with? "#EXT-X-STREAM-INF:"
          values = line[18..-1].split('=').map { |p|
              p.split(',')
          }.reduce([]) { |memo, i|
            if i.length == 1
              if memo.length == 0
                memo.push(i)
              else
                memo[-1].push(i)
              end
            else
              memo[-1].push(i[0..-2])
              memo.push([i[-1]])
            end

            memo
          }.reduce({}) { |memo, i|
            name = i[0].downcase.split('-').join('_').to_sym
            memo[name] = i[1..-1].join(',')

            memo
          }

          source_name = values[:video].gsub('"', '')
          true_resolution = values[:resolution].split('x').map { |val|
            val.to_i
          }.reduce { |product, val|
            product * val
          }

          sources.push({
            'video': source_name,
            'url': streams[i+1],
            'resolution': values[:resolution].gsub('"', ''),
            'true_resolution': true_resolution,
            'bandwidth': values[:bandwidth].to_f,
            'bitrate': bandwidth_to_human(values[:bandwidth].to_f)
          })

          skip = true
          next
        end
      end

      sources
    end
  end
end