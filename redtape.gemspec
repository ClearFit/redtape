# -*- encoding: utf-8 -*-
require File.expand_path('../lib/redtape/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Evan Light"]
  gem.email         = ["evan.light@tripledogdare.net"]
  gem.description   = %q{A handy dandy way to avoid using #accepts_nested_attributes_for}
  gem.summary       = %q{ Redtape provides an alternative to [ActiveRecord::NestedAttributes#accepts\_nested\_attributes\_for](http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html#method-i-accepts_nested_attributes_for) in the form of, well, a Form!  The initial implementation was heavily inspired by ["7 Ways to Decompose Fat Activerecord Models"](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/) by [Bryan Helmkamp](https://github.com/brynary).}
  gem.homepage      = "http://github.com/ClearFit/redtape"

  gem.files         = ["lib/redtape.rb", "lib/redtape/version.rb", "spec/form_spec.rb"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "redtape"
  gem.require_paths = ["lib"]
  gem.version       = Redtape::VERSION

  gem.add_runtime_dependency "activemodel"
  gem.add_runtime_dependency "activesupport"
end
