require 'virtus'

require 'active_support/core_ext/hash/indifferent_access'

require 'redtape'
require 'active_model'

class Address
  include Virtus
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attribute :address1,  String
  attribute :address2,  String
  attribute :city,      String
  attribute :state,     String
  attribute :zipcode,   String

  validates_presence_of :address1, :city, :state, :zipcode

  def persisted?
    valid?
  end

  def save
    valid?
  end
end

class User
  include Virtus
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attribute :name,      String
  attribute :addresses, Set[Address]

  validates_presence_of :name
  validate :name_contains_at_least_two_parts

  def name_contains_at_least_two_parts
    unless name =~ /.+ .+/
      errors.add(:name, "should contain at least two parts")
    end
  end

  def persisted?
    valid?
  end

  def save
    if addresses && addresses.present?
      return false unless addresses.all?(&:save)
    end
    valid?
  end
end

class RegistrationForm < Redtape::Form
  validates_and_saves :user

  attr_accessor :user

  attr_accessor :first_name, :last_name, :addresses_attributes

  def populate
    self.user = User.new(:name => "#{first_name} #{last_name}")
  end
end

class UserWithAddressesRegistrationForm < RegistrationForm
  def populate
    super

    self.user.addresses = addresses_attributes.map { |_, v|
      Address.new(v)
    }
  end
end


