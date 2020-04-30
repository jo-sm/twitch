require 'fileutils'
require 'json'

require_relative './constants.rb'

module Twitch
  module Utils
    module_function

    include Twitch::Constants

    def api(raw_uri, error_msg)
      client_id = CLIENT_ID

      uri = URI.parse(raw_uri)

      begin
        uri.open({
          'Client-ID' => client_id
        }).read
      rescue OpenURI::HTTPError => e
        abort "#{error_msg} (#{e})"
      end
    end

    def generate_url(url_string, options)
      url = url_string

      if options['params']
        url = url % options['params'].map { |k,v| [k.to_sym, v] }.reduce({}) { |memo, a| memo[a[0]] = a[1]; memo }
      end

      if options['url_params']
        url = "#{url}?#{URI.encode_www_form(options['url_params'])}"
      end

      url
    end

    def m3u8_url(type, token, opts)
      url = nil

      if type == 'live'
        url = generate_url(M3U8_URL_LIVE, {
          'params' => {
            'broadcaster' => opts['broadcaster']
          },
          'url_params' => {
            'token' => token["token"],
            'sig' => token["sig"],
            'allow_source' => true,
            'player_backend' => 'html5',
            'baking_bread' => true,
            'p' => Random.rand(1000000..9999999),
          }
        })
      elsif type == 'vod'
        url = generate_url(M3U8_URL_VOD, {
          'params' => {
            'video_id' => opts['video_id']
          },
          'url_params' => {
            'nauth' => token["token"],
            'nauthsig' => token["sig"],
            'allow_source' => true,
            'allow_spectre' => true,
            'p' => Random.rand(1000000..9999999),
            'baking_bread' => true
          }
        })
      end

      url
    end

    def get_vods_list(broadcaster, options)
      vods_url = generate_url(VODS_API_URL, {
        'params' => {
          'broadcaster' => broadcaster
        },
        'url_params' => {
          'broadcasts' => true,
          'limit' => options['limit']
        }
      })

      vods_raw = api(vods_url, "Error: Broadcaster does not exist")
      vods_list = JSON.parse(vods_raw)

      vods_list
    end

    def get_stream_data(broadcaster)
      stream_data_url = generate_url(STREAM_DATA_URL, {
        'params' => {
          'broadcaster' => broadcaster
        }
      })

      raw = api(stream_data_url, "Error: Could not get stream data")
      parsed = JSON.parse(raw)

      stream_data = parsed['stream']

      raise "Error: Stream is not live" unless stream_data
      channel_data = stream_data['channel']

      puts """
#{channel_data['display_name']} is live with #{channel_data["status"]}
Current game: #{stream_data["game"]}
Viewers: #{stream_data["viewers"]}

"""
    end

    def get_token(type, opts)
      token_base = nil

      if type == 'live'
        token_base = TOKEN_URL_LIVE
      elsif type == 'vod'
        token_base = TOKEN_URL_VOD
      end

      token_url = generate_url(token_base, {
        'params' => {
          'broadcaster' => opts['broadcaster'],
          'video_id' => opts['video_id']
        },
        'url_params' => {
          'adblock' => false,
          'need_https' => true,
          'platform' => 'web',
          'player_type' => 'site'
        }
      })

      raw_token = api(token_url, "Error: Unable to retrieve token")
      token = JSON.parse(raw_token)

      raise "Error: #{token["message"]}" if token["error"]

      token
    end

    def bandwidth_to_human(bandwidth)
      unit = 'b'

      if bandwidth > 1000000
        unit = 'mb'
        bandwidth = (bandwidth / 1000000).round(2)
      elsif bandwidth > 1000
        unit = 'kb'
        bandwidth = (bandwidth / 1000).round(2)
      end

      "#{bandwidth} #{unit}/s"
    end

    def persist_persistent_options(options)
      config = read_config

      # Remove previous "always_skip" option if present
      config.delete("always_skip")

      # Reset print_url config value if present and explicitly set to false
      if config['print_url'] and options['print_url'] == false
        config.delete('print_url')
      elsif options['print_url']
        config['print_url'] = true
      end

      if options['always']
        config['always'] = options['always']

        # TODO: debug printing
        # puts "Will always select stream with highest #{config['always']} in the future.\n\n"
      end

      write_config! config
    end

    def read_config
      config_home = File.join(Dir.home, ".twitch")
      filename = File.join(config_home, 'config')

      begin
        Dir.mkdir(config_home, 0755)
      rescue Errno::EEXIST
      end

      FileUtils.touch(filename)

      # Reads config file and attempts to parse its JSON
      file = open(filename, 'r')
      config = file.read
      file.close

      begin
        config = JSON.parse(config)
      rescue JSON::ParserError
        config = {}
      end

      config
    end

    def write_config!(config)
      config_home = File.join(Dir.home, ".twitch")
      filename = File.join(config_home, "config")

      config_file = open(filename, 'w')
      JSON.dump(config, config_file)
      config_file.close
    end

    def validate_options(options)
      if options['always']
        # Always takes precedence over resolution/bitrate selection, warn user
        if options['resolution'] or options['bitrate']
          return 'Warning: --always takes precedence over --bitrate or --resolution'
        end
      end

      if options['bitrate'] and options['resolution']
        return "The --bitrate and --resolution flags cannot be supplied together."
      end
    end

    def reset_config
      config = Twitch::Utils.read_config

      bcache = config["broadcasters"]

      config = { 'broadcasters' => bcache }

      Twitch::Utils.write_config! config
    end

    def rewrite_broadcasters_cache
      # A simple utility to take an existing broadcasters cache and rewrite
      # it to the new config file

      config_home = File.join(Dir.home, ".twitch")
      filename = File.join(config_home, 'broadcaster_cache')
      config = {}

      begin
        Dir.mkdir(config_home, 0755)
      rescue Errno::EEXIST
      end

      FileUtils.touch(filename)

      begin
      # Reads config file and attempts to parse its JSON
        io = open(filename, 'r')
        file = io.read

        begin
          broadcasters = JSON.parse(file)
        rescue JSON::ParserError
          return
        end

        io.close

        config["broadcasters"] = broadcasters
        write_config! config

        File.delete(filename)
      rescue Errno::ENOENT
        return
      end
    end

    def add_to_broadcasters_cache(broadcaster)
      config = read_config

      config["broadcasters"].is_a?(Array) or config["broadcasters"] = []

      config["broadcasters"] << broadcaster
      config["broadcasters"].uniq!

      write_config! config
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
            name = i[0].downcase.split('-').join('_')
            memo[name] = i[1..-1].join(',')

            memo
          }

          source_name = values['video'].gsub('"', '')
          true_resolution = values['resolution'].split('x').map { |val|
            val.to_i
          }.reduce { |product, val|
            product * val
          }

          sources.push({
            'video' => source_name,
            'url' => streams[i+1],
            'resolution' => values['resolution'].gsub('"', ''),
            'true_resolution' => true_resolution,
            'bandwidth' => values['bandwidth'].to_f
          })

          skip = true
          next
        end
      end

      sources
    end

    def ask_user_which_quality(sources, opts)
      config = read_config
      autoplay = nil

      if config["always"]
        autoplay = config["always"]
      elsif opts["bitrate"]
        autoplay = 'bitrate'
      elsif opts["resolution"]
        autoplay = 'resolution'
      end

      if autoplay
        if autoplay == 'resolution'
          # puts "Automatically selecting stream with highest resolution...\n"
          source = sources.max_by { |source| source['true_resolution'] }
        elsif autoplay == 'bitrate'
          # puts "Automatically selecting stream with highest bitrate...\n"
          source = sources.max_by { |source| source['bandwidth'] }
        end
      else
        puts "Available qualities:"

        sources.each_with_index do |source, i|
          puts "#{i+1}: #{source['resolution']} (#{bandwidth_to_human(source['bandwidth'])})"
        end

        print "Select quality: "
        index = $stdin.gets.strip.to_i

        while !sources[index-1] or (index < 1)
          puts "Error: Invalid selection"
          print "Select quality: "
          index = $stdin.gets.strip.to_i
        end

        source = sources[index-1]
      end

      source
    end
  end
end
