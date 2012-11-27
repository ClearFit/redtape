require 'active_support/core_ext/hash/indifferent_access'

require 'redtape'
require 'active_record'
require 'pry'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => 'development.db')

%w[models redtape].each do |path|
  Dir.glob("./spec/fixtures/#{path}/*").each do |r|
    require r[0...-3]
  end
end

RSpec.configure do |config|
  config.after(:each) do
    User.destroy_all
    Address.destroy_all
  end
end

ActiveRecord::Migrator.migrate("./spec/fixtures/db/migrate/")
