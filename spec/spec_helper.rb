require 'active_support/core_ext/hash/indifferent_access'

require 'redtape'
require 'active_record'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => 'development.db')

['./spec/fixtures/models/*', './spec/fixtures/forms/*'].each do |path|
  Dir.glob(path).each do |r|
    require r
  end
end

ActiveRecord::Migrator.migrate("./spec/fixtures/db/migrate/")
