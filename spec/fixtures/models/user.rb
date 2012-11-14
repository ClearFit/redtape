class User < ActiveRecord::Base
  has_many :addresses

  attr_accessible :name

  validates_presence_of :name
  validate :name_contains_at_least_two_parts

  def name_contains_at_least_two_parts
    unless name =~ /.+ .+/
      errors.add(:name, "should contain at least two parts")
    end
  end
end
