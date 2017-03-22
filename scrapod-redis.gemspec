# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path 'lib', File.dirname(__FILE__)

$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib

require 'scrapod/redis/version'

Gem::Specification.new do |spec|
  spec.name     = 'scrapod-redis'
  spec.version  = Scrapod::Redis::Version::VERSION
  spec.summary  = 'Scrapod data records in Redis'
  spec.homepage = 'https://github.com/krowpu/scrapod-redis'
  spec.license  = 'MIT'

  spec.author = 'krowpu'
  spec.email  = 'krowpu@tightmail.com'

  spec.description = <<-END.split("\n").map(&:strip).join ' '
    Scrapod data records in Redis
  END

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match %r{^(test|spec|features)/}
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename f }
  spec.require_paths = %w(lib)

  spec.add_runtime_dependency 'redis', '>= 4.0.0.rc1', '< 5.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake',    '~> 10.0'
  spec.add_development_dependency 'pry',     '~> 0.10'
  spec.add_development_dependency 'rubocop', '~> 0.47'
end
