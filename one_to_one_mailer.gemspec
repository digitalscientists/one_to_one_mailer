# -*- encoding: utf-8 -*-
require File.expand_path('../lib/one_to_one_mailer/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kmalyn"]
  gem.email         = ["kmalyn@softserveinc.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "one_to_one_mailer"
  gem.require_paths = ["lib"]
  gem.version       = OneToOneMailer::VERSION

  gem.add_development_dependency 'capistrano'
  gem.add_development_dependency 'railsless-deploy'
  
  gem.add_runtime_dependency 'tire'
  gem.add_runtime_dependency 'actionmailer'
  gem.add_runtime_dependency 'activesupport'
  gem.add_runtime_dependency 'slim'

end
