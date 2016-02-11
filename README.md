# FastInserter

Use raw SQL to insert database records in bulk. Supports uniqueness constraints, timestamps, and checking for existing records.

The motivation for this library from the fact that rails does validations on each and every inserted record in the join table. And, even if you pass validate: false, it still loads each record and inserts one by one. This leads to very slow insertion of large number (thoasands) of records.

This library skips active record altogether and uses raw sql to insert records. However, using raw sql goes around all your business logic, so we provide ways to still have niceties like uniqueness constraints and timestamps.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fast_inserter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fast_inserter

## Usage

In most cases, you probably don't want to use this library and instead should active record. However, should you need to use this library, usage instructions are below.

A basic usage for inserting multiple 'MassEmailsUser' records:

```ruby
@mass_email = MassEmail.find(params[:id])
user_ids = [1, 2, 3, 4] # ids to fast insert
params = {
  table: 'mass_emails_users',
  static_columns: {
    mass_email_id: @mass_email.id
  },
  additional_columns: {
    created_by_id: current_user.id
  },
  timestamps: true,
  unique: true,
  check_for_existing: true,
  variable_column: 'user_id',
  values: user_ids
}
inserter = FastInserter::Base.new(params)
inserter.fast_insert
```

Let's walkthrough the options.

### table

Defines the table name to insert into

### static_columns

These are columns and the values for the columns which will not change for each insertion.

### additional_columns

These are also static columns which will not changed, but these columns will not be used for uniqueness validation constraints.

### timestamps

Includes created_at and updated_at timestamps to each record.

### unique

Ensures that all items in the 'values' parameter are unique.

### check_for_existing

Queries the database for any values which already exist. This uses 'static_columns' and 'variable_column' for determining uniqueness.

### variable_column

The name of the column which we will be dynamically inserting records for

### values

The large list of values to insert for the 'variable_column' value.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/strydercorp/fast_inserter.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

