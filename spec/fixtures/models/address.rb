class Address < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :address1, :city, :state, :zipcode
end
