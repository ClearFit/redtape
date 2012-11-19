require 'spec_helper'

describe Redtape::Form do
  context "given a Form accepting a first and last name that creates a User" do
    context "with valid data" do
      subject {
        RegistrationForm.new({
          :first_name => "Evan",
          :last_name => "Light"
        }, {
          :factory_class => UserFactory
        })
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
      subject { RegistrationForm.new({:first_name => "Evan"}, :factory_class => UserFactory) }

      context "after saving the form" do
        before do
          subject.save
        end

        specify { subject.should_not be_valid }
        specify { subject.should_not be_persisted }
        specify { subject.errors.should have_key(:name) }
        specify { subject.user.should_not be_valid }
      end
    end
  end

  context "given another Form subclass" do
    before do
      Class.new(Redtape::Form) do
        validates_and_saves :test_object
      end.new(:test_object => :foo)
    end

    subject { RegistrationForm.new({}, :factory_class => UserFactory) }

    context "RegistrationForm still saves User" do
      before do
        subject.save
      end

      specify { subject.should_not be_valid }
    end
  end
end
