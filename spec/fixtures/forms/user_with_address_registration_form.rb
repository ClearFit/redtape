require 'fixtures/forms/registration_form'

class UserWithAddressesRegistrationForm < RegistrationForm
  attr_accessor :addresses_attributes

  # NOTE: This handles *either* new records or updated records and not both at the
  # same time.  It's up to the Form subclass to decide how many cases it will support.
  # Your forms may not need more than just new or new-and-update.
  def populate(attrs, model)
    super

    if attrs[:addresses_attributes].present?
      attrs[:addresses_attributes].each do |_, address_attrs|
        address =
          if address_attrs[:id]
            m = model.addresses.map { |a| a if a.id == address_attrs[:id] }.compact.first
            @updated_records << m
            m
          else
            Address.new.tap do |a|
              model.addresses << a
            end
          end
        address.attributes = address.attributes.merge(address_attrs)
      end
    end

    model
  end
end
