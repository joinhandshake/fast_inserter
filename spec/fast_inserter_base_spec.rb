require 'spec_helper'

describe FastInserter do
  describe "defaults" do
    it "has a default group size of 2,000 which is low enough to avoid locks and high enough to be performant" do
      expect(FastInserter::Base::DEFAULT_GROUP_SIZE).to eq 2_000
    end
  end

  describe "fast inserting" do
    it "correctly inserts data when values are strings" do
      mass_email = create_mass_email
      fake_email_addresses = ["student@amaranta.edu", "recruiter@fb.com"]

      join_params = {
        table: 'mass_email_emails',
        static_columns: {
          mass_email_id: mass_email.id
        },
        variable_column: 'email_address',
        values: fake_email_addresses
      }
      inserter = FastInserter::Base.new(join_params)
      expect(mass_email.mass_email_emails.count).to eq 0
      inserter.fast_insert

      expect(mass_email.mass_email_emails.count).to eq 2
      expect(mass_email.mass_email_emails.pluck(:email_address)).to eq fake_email_addresses
    end

    it "supports multiple variable columns" do
      event = create_event
      user_ids = [1, 2, 3, 4]
      registered = [true, true, false, false]
      checked_in = [true, false, true, false]

      join_params = {
        table: 'attendees',
        static_columns: {
          attendable_id: event.id,
          attendable_type: 'Event'
        },
        variable_columns: %w(user_id registered checked_in),
        values: user_ids.zip(registered, checked_in),
        options: {
          timestamps: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(event.attendees.count).to eq 0
      inserter.fast_insert

      expect(event.attendees.count).to eq 4
      expect(event.attendees.find_by(user_id: 1).registered).to eq true
      expect(event.attendees.find_by(user_id: 1).checked_in).to eq true

      expect(event.attendees.find_by(user_id: 2).registered).to eq true
      expect(event.attendees.find_by(user_id: 2).checked_in).to eq false

      expect(event.attendees.find_by(user_id: 3).registered).to eq false
      expect(event.attendees.find_by(user_id: 3).checked_in).to eq true

      expect(event.attendees.find_by(user_id: 4).registered).to eq false
      expect(event.attendees.find_by(user_id: 4).checked_in).to eq false
    end

    it "only inserts unique values when unique option is set" do
      mass_email = create_mass_email
      fake_email_addresses = ["student@amaranta.edu", "recruiter@fb.com", "recruiter@fb.com"]

      # There are indeed duplicates
      expect(fake_email_addresses.count).to_not eq fake_email_addresses.uniq.count

      join_params = {
        table: 'mass_email_emails',
        static_columns: {
          mass_email_id: mass_email.id
        },
        variable_column: 'email_address',
        values: fake_email_addresses,
        options: {
          unique: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(mass_email.mass_email_emails.count).to eq 0
      inserter.fast_insert

      expect(mass_email.mass_email_emails.count).to eq 2
      expect(mass_email.mass_email_emails.pluck(:email_address)).to eq fake_email_addresses.uniq
    end

    it "only inserts unique values when unique option is set, even with multiple pages of insertion (group_size < inserted records)" do
      event = create_event
      user_ids = [1, 2, 3, 4, 1] # contains a duplicate

      join_params = {
        table: 'attendees',
        static_columns: {
          attendable_id: event.id,
          attendable_type: ::Event.name
        },
        additional_columns: {
          registered: true
        },
        variable_column: 'user_id',
        values: user_ids,
        options: {
          timestamps: true,
          unique: true,
          check_for_existing: true
        },
        group_size: 1 # This ensures it gets broken up and is important to this test
      }

      # Create an inserter which receives 4 groups of ids and inserts 4 notification preferences
      inserter = FastInserter::Base.new(join_params)
      expect(inserter).to receive(:fast_insert_group).exactly(4).times.and_call_original
      expect(event.attendees.count).to eq 0
      inserter.fast_insert

      # Make sure that each is created, one per user, and each has timestamps set properly
      expect(event.attendees.count).to eq 4
      expect(event.attendees.pluck(:user_id)).to match_array user_ids.uniq
      expect(event.attendees.pluck(:created_at).compact.count).to eq 4
      expect(event.attendees.pluck(:updated_at).compact.count).to eq 4
    end

    it "correctly adds timestamp columns when timestamp option is set" do
      event = create_event
      user_ids = [1, 2, 3, 4]

      join_params = {
        table: 'attendees',
        static_columns: {
          attendable_id: event.id,
          attendable_type: 'Event'
        },
        variable_column: 'user_id',
        values: user_ids,
        options: {
          timestamps: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(event.attendees.count).to eq 0
      inserter.fast_insert

      expect(event.attendees.count).to eq 4
      expect(event.attendees.first.created_at).to_not eq nil
      expect(event.attendees.first.updated_at).to_not eq nil
      expect(event.attendees.first.created_at).to eq event.attendees.first.updated_at
    end

    it "correctly sets additional columns" do
      other_user_id = 5
      event = create_event
      user_ids = [1, 2, 3, 4]

      join_params = {
        table: 'attendees',
        static_columns: {
          attendable_id: event.id,
          attendable_type: 'Event',
          created_by_id: other_user_id,
          updated_by_id: other_user_id
        },
        variable_column: 'user_id',
        values: user_ids,
        options: {
          timestamps: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(event.attendees.count).to eq 0
      inserter.fast_insert

      expect(event.attendees.count).to eq 4
      expect(event.attendees.pluck(:created_by_id)).to eq [other_user_id, other_user_id, other_user_id, other_user_id]
      expect(event.attendees.pluck(:updated_by_id)).to eq [other_user_id, other_user_id, other_user_id, other_user_id]
    end

    it "doesn't insert existing values when check_for_existing option is set" do
      event = create_event
      user_ids = [1, 2, 3, 4]

      join_params = {
        table: 'attendees',
        static_columns: {
          attendable_id: event.id,
          attendable_type: 'Event'
        },
        variable_column: 'user_id',
        values: user_ids,
        options: {
          timestamps: true,
          check_for_existing: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(event.attendees.count).to eq 0
      inserter.fast_insert

      expect(event.attendees.count).to eq 4
      created_at = event.attendees.first.created_at
      updated_at = event.attendees.first.updated_at

      # Now do a second round of inserting, including the old values, and expect no duplicates
      next_user_ids = [5, 6, 7, 8]
      join_params[:values] = (user_ids + next_user_ids)
      inserter = FastInserter::Base.new(join_params)
      inserter.fast_insert

      expect(event.attendees.count).to eq 8
      expect(event.attendees.first.created_at).to eq created_at
      expect(event.attendees.first.updated_at).to eq updated_at
      expect(event.attendees.pluck(:user_id)).to match_array (user_ids + next_user_ids)
    end

    it "doesn't insert existing values what a static column is null" do
      event = create_event
      user_ids = [1, 2, 3, 4]

      join_params = {
        table: 'attendees',
        static_columns: {
          attendable_id: event.id,
          attendable_type: 'Event',
          created_by_id: nil
        },
        variable_column: 'user_id',
        values: user_ids,
        options: {
          timestamps: true,
          check_for_existing: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(event.attendees.count).to eq 0
      inserter.fast_insert

      expect(event.attendees.count).to eq 4
      created_at = event.attendees.first.created_at
      updated_at = event.attendees.first.updated_at

      # Now do a second round of inserting, including the old values, and expect no duplicates
      next_user_ids = [5, 6, 7, 8]
      join_params[:values] = (user_ids + next_user_ids)
      inserter = FastInserter::Base.new(join_params)
      inserter.fast_insert

      expect(event.attendees.count).to eq 8
      expect(event.attendees.first.created_at).to eq created_at
      expect(event.attendees.first.updated_at).to eq updated_at
      expect(event.attendees.pluck(:user_id)).to match_array (user_ids + next_user_ids)
    end

    it "doesn't include the additional data when finding existing" do
      user_id = 9
      event = create_event
      user_ids = [1, 2, 3, 4]

      join_params = {
        table: 'attendees',
        static_columns: {
          attendable_id: event.id,
          attendable_type: 'Event'
        },
        additional_columns: {
          created_by_id: user_id
        },
        variable_column: 'user_id',
        values: user_ids,
        options: {
          timestamps: true,
          check_for_existing: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(event.attendees.count).to eq 0
      inserter.fast_insert

      expect(event.attendees.count).to eq 4
      created_at = event.attendees.first.created_at
      updated_at = event.attendees.first.updated_at

      # Now do a second round of inserting, including the old values, and expect no duplicates
      next_user_ids = [5, 6, 7, 8]
      join_params[:values] = user_ids + next_user_ids
      inserter = FastInserter::Base.new(join_params)
      inserter.fast_insert

      expect(event.attendees.count).to eq 8
      expect(event.attendees.first.created_at).to eq created_at
      expect(event.attendees.first.updated_at).to eq updated_at
      expect(event.attendees.pluck(:user_id)).to match_array user_ids + next_user_ids
    end

    it "doesn't insert existing values when check_for_existing option is set and values are strings" do
      mass_email = create_mass_email
      email_addresses = ['email1@example.com', 'email2@example.com']

      join_params = {
        table: 'mass_email_emails',
        static_columns: {
          mass_email_id: mass_email.id
        },
        variable_column: 'email_address',
        values: email_addresses,
        options: {
          check_for_existing: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(mass_email.mass_email_emails.count).to eq 0
      inserter.fast_insert

      expect(mass_email.mass_email_emails.count).to eq 2

      # Now do a second round of inserting, including the old values, and expect no duplicates
      next_email_addresses = ['email3@example.com', 'email4@example.com']
      join_params[:values] = email_addresses + next_email_addresses
      inserter = FastInserter::Base.new(join_params)
      inserter.fast_insert

      expect(mass_email.mass_email_emails.count).to eq 4
      expect(mass_email.mass_email_emails.pluck(:email_address)).to match_array email_addresses + next_email_addresses
    end

    it "scopes existing values check to static columns when check_for_existing option is set" do
      event = create_event
      event2 = create_event
      user_ids = [1,2,3,4]

      # first insert into event
      join_params = {
        table: 'attendees',
        static_columns: {
          attendable_id: event.id,
          attendable_type: 'Event'
        },
        variable_column: 'user_id',
        values: user_ids,
        options: {
          timestamps: true,
          check_for_existing: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(event.attendees.count).to eq 0
      inserter.fast_insert

      expect(event.attendees.count).to eq 4
      expect(event.attendees.pluck(:user_id)).to match_array user_ids

      # now insert into event2 and expect it to not care about the other user ids already
      # present in event
      join_params = {
        table: 'attendees',
        static_columns: {
          attendable_id: event2.id,
          attendable_type: 'Event'
        },
        variable_column: 'user_id',
        values: user_ids,
        options: {
          timestamps: true,
          check_for_existing: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(event2.attendees.count).to eq 0
      inserter.fast_insert

      join_params[:values] = user_ids
      inserter = FastInserter::Base.new(join_params)
      inserter.fast_insert

      expect(event2.attendees.count).to eq 4
      expect(event2.attendees.pluck(:user_id)).to match_array user_ids
    end
  end
end
