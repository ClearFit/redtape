require 'virtus'

require 'redtape'
require 'active_model'

class TestUser
  include Virtus

  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attribute :name, String

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
    valid?
  end
end

class TestRegistrationForm < Redtape::Form
  validates_and_saves :test_user

  attr_accessor :test_user

  attr_accessor :first_name, :last_name

  def populate
    self.test_user = TestUser.new(:name => "#{first_name} #{last_name}")
  end
end

describe Redtape::Form do
  context "given a Form accepting a first and last name that creates a User" do
    context "with valid data" do
      subject {
        TestRegistrationForm.new.tap do |f|
          f.first_name = "Evan"
          f.last_name = "Light"
        end
      }

      context "after saving the form" do
        before do
          subject.save
        end

        specify { subject.should be_valid }
        specify { subject.test_user.should be_valid }
        specify { subject.test_user.should be_persisted }
      end
    end

    context "with invalid data" do
      subject {
        TestRegistrationForm.new.tap do |f|
          f.first_name = "Evan"
        end
      }

      context "after saving the form" do
        before do
          subject.save
        end

        specify { subject.should_not be_valid }
        specify { subject.should_not be_persisted }
        specify { subject.errors.should have_key(:name) }
        specify { subject.test_user.should_not be_valid }
      end
    end
  end
end
