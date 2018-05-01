lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'hikvision/version'

Gem::Specification.new do |spec|
  spec.name        = 'hikvision-ruby'
  spec.version     = Hikvision::VERSION
  spec.authors     = ['Maxwell Pray']
  spec.email       = ['synthead@gmail.com']
  spec.summary     = 'Control Hikvision hardware.'
  spec.description = 'Control Hikvision hardware.'
  spec.homepage    = 'https://github.com/synthead/hikvision-ruby'
  spec.license     = 'GPL-3.0'

  spec.files       = Dir.glob('lib/**/*')

  spec.add_dependency 'excon',         '~> 0.60.0'
  spec.add_dependency 'faraday',       '~> 0.14.0'
  spec.add_dependency 'activesupport', '~> 5.2.0'
end
