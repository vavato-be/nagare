# frozen_string_literal: true

require_relative 'lib/nagare/version'

Gem::Specification.new do |spec|
  spec.name          = 'nagare-redis'
  spec.version       = Nagare::VERSION
  spec.authors       = ['Alex Reis']
  spec.email         = ['alex@alexmreis.com']

  spec.summary       = 'Persistent and resilient pub/sub using Redis Streams'
  spec.description   = 'Nagare is a wrapper around Redis Streams that enables '\
                       'event-driven architectures and pub/sub messaging with'\
                       'durable subscribers'
  spec.homepage      = 'https://github.com/vavato-be/nagare'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/vavato-be/nagare.git'
  spec.metadata['changelog_uri'] = 'https://github.com/vavato-be/nagare/CHANGELOG.md'

  spec.add_dependency 'redis', '~> 6.2', '>= 6.2.0'
  spec.add_development_dependency 'rubocop', '~> 1.18.3', '>= 1.18.3'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.4.0', '>= 2.4.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir = 'exe'
  spec.executables << 'nagare'
  spec.require_paths = ['lib']
end
