require 'spec_helper'

describe Redtape::Form do
  context "given a Form where the Form fields are a proper subset of the modeled fields" do
    context "where across all involved objects" do
      context "all field names are unique" do
        context "and the data is invalid" do
          context "in a root object" do
            it "reports an error on the model as <field_name>"
          end
          context "in a nested belongs_to/has_one" do
            it "reports an error on the model as <model_name>_<field_name>"
          end
        end
      end

      context "some field names overlap" do
      end
    end
  end

  context "when #populate is not defined in the subclass" do
    context "the default implementation" do
      it "uses the value(s) passed to validate_and_save to locate the model params to use for population"
      it "looks up the classified name for the symbol passes to validate_and_saves"
    end
  end

  context "given a Form accepting a first and last name that creates a User" do
    context "with valid data" do
      subject {
        RegistrationForm.new(
          :first_name => "Evan",
          :last_name => "Light"
        )
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
      subject { RegistrationForm.new(:first_name => "Evan") }

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

    subject { RegistrationForm.new }

    context "RegistrationForm still saves User" do
      before do
        subject.save
      end

      specify { subject.should_not be_valid }
    end
  end
end
