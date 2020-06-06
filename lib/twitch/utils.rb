module Twitch
  module Utils
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
  end
end
