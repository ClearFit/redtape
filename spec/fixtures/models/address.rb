class Address < ActiveRecord::Base
  validates_presence_of :address1, :city, :state, :zipcode
end
