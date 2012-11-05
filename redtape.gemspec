# -*- encoding: utf-8 -*-
require File.expand_path('../lib/redtape/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Evan Light"]
  gem.email         = ["evan.light@tripledogdare.net"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = ["lib/redtape.rb", "spec/form_spec.rb"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "redtape"
  gem.require_paths = ["lib"]
  gem.version       = Redtape::VERSION

  gem.add_development_dependency "virtus"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rails"

  gem.add_runtime_dependency "activemodel"
end
