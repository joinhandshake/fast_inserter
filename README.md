# FastInserter

[![Gem Version](https://badge.fury.io/rb/fast_inserter.svg)](https://badge.fury.io/rb/fast_inserter)
[![Build Status](https://travis-ci.org/joinhandshake/fast_inserter.svg?branch=master)](https://travis-ci.org/joinhandshake/fast_inserter)

Use raw SQL to insert database records in bulk, fast. Supports uniqueness constraints, timestamps, and checking for existing records.

The motivation for this library comes from the fact that rails does validations on each and every inserted record in the join table. And, even if you pass validate: false, it still loads each record and inserts one by one. This is all good, but also means inserting a large number (thousands) of records is slow.

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

## Runtime dependencies

* activerecord: Fast inserter depends on active record for handling database connections, database configuration, executing the sql, and sql sanitization.

## Usage

*We wrote a longer post about this gem at https://joinhandshake.com/engineering/2016/01/26/quickly-inserting-thousands-of-records-in-rails.html*

In most cases, you probably don't want to use this library and instead should use active record. However, should you need to use this library, usage instructions are below.

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
  options: {
    timestamps: true,
    unique: true,
    check_for_existing: true
  },
  group_size: 2_000,
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

Includes created_at and updated_at timestamps to each record. Default is false.

### unique

Ensures that the 'values' parameter is a unique set of values. Default is false.

### check_for_existing

Queries the table for any values which already exist and removes them from the values to be inserted. This query uses 'static_columns' and 'variable_column' for determining uniqueness. Default is false.

### group_size

Insertions will be broken up into batches. This specifies the number of records you want to insert per batch. Default is 2,000.

### variable_column

The name of the column which we will be dynamically inserting records for. This is the only column which changes per-record being inserted.

### values

The large list of values to use for the 'variable_column' value when inserting the records.

## Multiple Variable Columns
Rather than a single `variable_column`, you may pass an array of `variable_columns`, along with `values` as an array of arrays.

Example:
```
variable_columns: %w(user_id user_email)
values: [[1, 'foo@example.com'], [2, 'bar@example.com']]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joinhandshake/fast_inserter. All code must run on sqlite, pg, and mysql (tests are set up CI already).


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
