# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twitch/version'

Gem::Specification.new do |spec|
  spec.name          = "twitch"
  spec.version       = Twitch::VERSION
  spec.authors       = ["Joshua Smock"]

  spec.summary       = %q{Watch Twitch streams or vods locally on your Mac using Quicktime}
  spec.homepage      = "https://github.com/jo-sm/twitch"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = [ 'twitch' ]
  spec.require_paths = [ "lib" ]

  spec.add_development_dependency "bundler", "~> 2.1.0"
end
