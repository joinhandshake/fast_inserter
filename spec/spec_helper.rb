$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_record'
require 'fast_inserter'
require 'database_cleaner'
require 'support/model_macros'
require 'yaml'

# Set up active record based on this tests database gem (matrix of multiple)
configs = YAML.load_file('spec/support/database.yml')
db_name = ENV['DB'] || 'sqlite'
ActiveRecord::Base.establish_connection(configs[db_name])

puts configs[db_name]

require 'support/models'

RSpec.configure do |config|
  config.include ModelMacros

  # This means that before the suite runs as a whole, truncate the whole database
  # and leftover records (should skip schema_migrations table).
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
