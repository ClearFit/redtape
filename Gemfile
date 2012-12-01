source 'https://rubygems.org'

# Specify your gem's dependencies in redtape.gemspec
gemspec

group :development do
  gem 'minitest'
  gem 'virtus'
  gem 'rspec'
  gem 'rails'
  gem 'pry'

  platform :ruby do
    gem 'sqlite3'
  end

  platform :jruby do
    gem 'activerecord-jdbcsqlite3-adapter'
  end
end
