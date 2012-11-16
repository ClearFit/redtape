require 'fixtures/forms/registration_form'

class UserWithAddressesRegistrationForm < RegistrationForm
  attr_accessor :addresses_attributes

  # NOTE: This handles *either* new records or updated records and not both at the
  # same time.  It's up to the Form subclass to decide how many cases it will support.
  # Your forms may not need more than just new or new-and-update.
  def populate_individual_record(record, attrs)
    super

    if record.is_a?(Address)
      record.attributes = record.attributes.merge(attrs)
    end
  end
end
