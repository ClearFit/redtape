module RegistrationRedtape
  def populate_individual_record(record, attrs)
    if record.is_a?(User)
      record.name = "#{attrs[:first_name]} #{attrs[:last_name]}"
    end
  end
end
