require 'spec_helper'

class RegistrationController
  include RegistrationRedtape
end

describe Redtape::Form do
  subject { Redtape::Form.new(controller_stub, :model_accessor => :user) }

  context "given a Form accepting a first and last name that creates a User" do
    context "with valid data" do
      let (:controller_stub) {
        RegistrationController.new.tap do |c|
          c.stub(:params).and_return({
            :user => {
              :first_name => "Evan",
              :last_name => "Light"
            }
          })
        end
      }

      context "after saving the form" do
        before do
          subject.save
        end

        specify { subject.should be_valid }
        specify { subject.user.should be_valid }
        specify { subject.user.should be_persisted }
      end

      context "after validating the form" do
        before do
          subject.valid?
        end

        specify { subject.user.should be_valid }
      end
    end

    context "with invalid data" do
      let (:controller_stub) {
        RegistrationController.new.tap do |c|
          c.stub(:params).and_return({
            :user => {
              :first_name => "Evan"
            }
          })
        end
      }

      context "after saving the form" do
        before do
          subject.save
        end

        specify { subject.should_not be_valid }
        specify { subject.should_not be_persisted }
        specify { binding.pry; subject.errors.should have_key(:name) }
        specify { subject.user.should_not be_valid }
      end
    end
  end
end
