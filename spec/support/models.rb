require 'active_record'

load File.dirname(__FILE__) + '/schema.rb'

# The Address model will use the default options
class Attendee < ActiveRecord::Base
  belongs_to :user
  belongs_to :attendable, polymorphic: true
  belongs_to :created_by, polymorphic: true
  belongs_to :updated_by, polymorphic: true
end

class Event < ActiveRecord::Base
  has_many :attendees, as: :attendable
end

class MassEmail < ActiveRecord::Base
  has_many :mass_email_emails
end

class MassEmailEmail < ActiveRecord::Base
end

class Survey < ActiveRecord::Base
  has_many :survey_recipients
end
