module ModelMacros
  def create_attendee
    Attendee.create!(
      attendable: create_event,
      user_id: 1
    )
  end

  def create_event
    Event.create!(
      name: "Event Name"
    )
  end

  def create_mass_email
    MassEmail.create!(
      name: "Mass email name"
    )
  end

  def create_survey
    Survey.create!(
      title: "Survey name"
    )
  end
end
