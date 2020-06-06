require 'json'
require 'fileutils'

module Twitch
  module Config
    def persist_persistent_options(options)
      config = read_config

      # Reset print_url config value if present and explicitly set to false
      if config[:print_url] and options[:print_url] == false
        config.delete(:print_url)
      elsif options[:print_url]
        config[:print_url] = true
      end

      if options[:always]
        config[:always] = options[:always]

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
        config = JSON.parse(config, :symbolize_names => true)
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
      if options[:always]
        # Always takes precedence over resolution/bitrate selection, warn user
        if options[:resolution] or options[:bitrate]
          return 'Warning: --always takes precedence over --bitrate or --resolution'
        end
      end

      if options[:bitrate] and options[:resolution]
        return "The --bitrate and --resolution flags cannot be supplied together."
      end
    end

    def reset_config
      config = read_config

      bcache = config[:broadcasters]

      config = { 'broadcasters': bcache }

      write_config! config
    end

    def add_to_broadcasters_cache(broadcaster)
      config = read_config

      config[:broadcasters].is_a?(Array) or config[:broadcasters] = []

      config[:broadcasters] << broadcaster
      config[:broadcasters].uniq!

      write_config! config
    end
  end
end