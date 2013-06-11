# -*- encoding: utf-8 -*-
require File.expand_path('../lib/upstart_unicorn_launcher/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tom Ward"]
  gem.email         = ["tom@popdog.net"]
  gem.description   = %q{Launch unicorn with upstart}
  gem.summary       = %q{Helps launch unicorn using upstart process management}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "upstart-unicorn-launcher"
  gem.require_paths = ["lib"]
  gem.version       = UpstartUnicornLauncher::VERSION

  gem.add_dependency 'unicorn'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'curb'
end
