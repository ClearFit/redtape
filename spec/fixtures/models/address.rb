class Address < ActiveRecord::Base
  belongs_to :user

  attr_accessible :address1, :address2, :city, :state, :zipcode, :alarm_code, :user_id

  validates_presence_of :address1, :city, :state, :zipcode
end
