class UserWithAddressesRegistrationForm < RegistrationForm
  attr_accessor :addresses_attributes

  def populate
    super

    self.user.addresses = addresses_attributes.map { |_, v|
      Address.new(v)
    }
  end
end
