class PhoneNumber < ActiveRecord::Base
  validates_presence_of :country_code, :area_code, :number

  attr_accessible :country_code, :area_code, :number
end
