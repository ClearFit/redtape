require 'active_support/core_ext/hash/indifferent_access'

require 'redtape'
require 'active_record'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => 'development.db')


%w[models forms].each do |path|
  Dir.glob("./spec/fixtures/#{path}/*").each do |r|
    require r[0...-3]
  end
end

ActiveRecord::Migrator.migrate("./spec/fixtures/db/migrate/")
