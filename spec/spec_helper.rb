$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_record'
require 'fast_inserter'
require 'database_cleaner'
require 'support/model_macros'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
# ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), "../log/debug.log"))
# ActiveRecord::Base.send(:include, CanBe::ModelExtensions)

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
