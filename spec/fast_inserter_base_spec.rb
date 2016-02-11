require 'spec_helper'

describe FastInserter do
  describe "fast inserting" do
    it "correctly inserts data when values are strings" do
      mass_email = FactoryGirl.create(:mass_email)
      fake_email_addresses = ["student@amaranta.edu", "recruiter@fb.com"]

      join_params = {
        join_table: 'mass_email_emails',
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

    it "only inserts unique values when unique option is set" do
      survey = FactoryGirl.create(:survey)
      users = FactoryGirl.create_list(:student_user, 4)
      user_ids = users.map(&:id) + [users.first.id] # contains a duplicate

      join_params = {
        join_table: 'survey_requests',
        static_columns: {
          survey_id: survey.id
        },
        variable_column: 'user_id',
        values: user_ids,
        options: {
          unique: true
        }
      }
      inserter = FastInserter::Base.new(join_params)
      expect(survey.survey_requests.count).to eq 0
      inserter.fast_insert

      expect(survey.survey_requests.count).to eq 4
      expect(survey.survey_requests.pluck(:user_id)).to match_array users.map(&:id)
    end

    it "only inserts unique values when unique option is set, even with multiple pages" do
      notification_reason = FactoryGirl.create(:notification_reason)
      communication_type = FactoryGirl.create(:email_communication_type)
      users = FactoryGirl.create_list(:student_user, 4)
      user_ids = users.map(&:id) + [users.first.id] # contains a duplicate

      join_params = {
        join_table: 'notification_preferences',
        static_columns: {
          notification_reason_id: notification_reason.id,
          communication_type_id: communication_type.id,
        },
        additional_columns: {
          frequency: 'immediately'
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
      expect(notification_reason.notification_preferences.count).to eq 0
      inserter.fast_insert

      # Make sure that each is created, one per user, and each has timestamps set properly
      expect(notification_reason.notification_preferences.count).to eq 4
      expect(notification_reason.notification_preferences.pluck(:user_id)).to match_array users.map(&:id)
      expect(notification_reason.notification_preferences.pluck(:created_at).compact.count).to eq 4
      expect(notification_reason.notification_preferences.pluck(:updated_at).compact.count).to eq 4
    end

    it "correctly adds timestamp columns when timestamp option is set" do
      event = FactoryGirl.create(:event)
      users = FactoryGirl.create_list(:student_user, 4)
      user_ids = users.map(&:id)

      join_params = {
        join_table: 'attendees',
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
      other_user = FactoryGirl.create(:admin_user)
      event = FactoryGirl.create(:event)
      users = FactoryGirl.create_list(:student_user, 4)
      user_ids = users.map(&:id)

      join_params = {
        join_table: 'attendees',
        static_columns: {
          attendable_id: event.id,
          attendable_type: 'Event',
          created_by_id: other_user.id,
          updated_by_id: other_user.id
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
      expect(event.attendees.pluck(:created_by_id)).to eq [other_user.id, other_user.id, other_user.id, other_user.id]
      expect(event.attendees.pluck(:updated_by_id)).to eq [other_user.id, other_user.id, other_user.id, other_user.id]
    end

    it "doesn't insert existing values when check_for_existing option is set" do
      event = FactoryGirl.create(:event)
      users = FactoryGirl.create_list(:student_user, 4)
      user_ids = users.map(&:id)

      join_params = {
        join_table: 'attendees',
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
      next_users = FactoryGirl.create_list(:student_user, 4)
      next_user_ids = next_users.map(&:id)
      join_params[:values] = user_ids + next_user_ids
      inserter = FastInserter::Base.new(join_params)
      inserter.fast_insert

      expect(event.attendees.count).to eq 8
      expect(event.attendees.first.created_at).to eq created_at
      expect(event.attendees.first.updated_at).to eq updated_at
      expect(event.attendees.pluck(:user_id)).to match_array user_ids + next_user_ids
    end

    it "doesn't include the additional data when finding existing" do
      user = FactoryGirl.create(:admin_user)
      event = FactoryGirl.create(:event)
      users = FactoryGirl.create_list(:student_user, 4)
      user_ids = users.map(&:id)

      join_params = {
        join_table: 'attendees',
        static_columns: {
          attendable_id: event.id,
          attendable_type: 'Event'
        },
        additional_columns: {
          created_by_id: user.id
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
      next_users = FactoryGirl.create_list(:student_user, 4)
      next_user_ids = next_users.map(&:id)
      join_params[:values] = user_ids + next_user_ids
      inserter = FastInserter::Base.new(join_params)
      inserter.fast_insert

      expect(event.attendees.count).to eq 8
      expect(event.attendees.first.created_at).to eq created_at
      expect(event.attendees.first.updated_at).to eq updated_at
      expect(event.attendees.pluck(:user_id)).to match_array user_ids + next_user_ids
    end

    it "doesn't insert existing values when check_for_existing option is set and values are strings" do
      mass_email = FactoryGirl.create(:mass_email)
      users = FactoryGirl.create_list(:student_user, 2)
      email_addresses = users.map(&:email_address)

      join_params = {
        join_table: 'mass_email_emails',
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
      next_users = FactoryGirl.create_list(:student_user, 2)
      next_email_addresses = next_users.map(&:email_address)
      join_params[:values] = email_addresses + next_email_addresses
      inserter = FastInserter::Base.new(join_params)
      inserter.fast_insert

      expect(mass_email.mass_email_emails.count).to eq 4
      expect(mass_email.mass_email_emails.pluck(:email_address)).to match_array email_addresses + next_email_addresses
    end

    it "scopes existing values check to static columns when check_for_existing option is set" do
      event = FactoryGirl.create(:event)
      event2 = FactoryGirl.create(:event)
      users = FactoryGirl.create_list(:student_user, 4)
      user_ids = users.map(&:id)

      # first insert into event
      join_params = {
        join_table: 'attendees',
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
        join_table: 'attendees',
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
