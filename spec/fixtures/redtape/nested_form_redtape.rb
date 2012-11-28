module NestedFormRedtape
  def populate_individual_record(record, attrs)
    if record.is_a?(User)
      record.name = "#{attrs[:first_name]} #{attrs[:last_name]}"
    elsif record.is_a?(Address)
      record.attributes = record.attributes.merge(attrs)
    end
  end

  def model_accessor
    :user
  end
end
