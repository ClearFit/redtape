require 'spec_helper'

describe "Using the default ModelFactory" do
  let(:create_params) {
    HashWithIndifferentAccess.new(
      :name                   => "Evan Light",
      :social_security_number => "123-456-7890",
      :addresses_attributes => {
        "0" => {
          :address1   => "123 Foobar way",
          :city       => "Foobar",
          :state      => "MN",
          :zipcode    => "12345",
          :alarm_code => "12345"
        },
        "1" => {
          :address1   => "124 Foobar way",
          :city       => "Foobar",
          :state      => "MN",
          :zipcode    => "12345",
          :alarm_code => "12345"
        }
      }
    )
  }

  let(:update_params) {
    HashWithIndifferentAccess.new(
      :id                     => User.last.id,
      :name                   => "Evan Not-so-bright-light",
      :social_security_number => "000-000-0000",
      :addresses_attributes => {
        "0" => {
          :id         => Address.first.id,
          :address1   => "456 Foobar way",
          :city       => "Foobar",
          :state      => "MN",
          :zipcode    => "12345",
          :alarm_code => "00000"
        },
        "1" => {
          :id         => Address.last.id,
          :address1   => "124 Foobar way",
          :city       => "Foobar",
          :state      => "MN",
          :zipcode    => "12345",
          :alarm_code => "12345"
        }
      }
    )
  }

  context "when creating records" do
    before do
      AutomatedRegistrationForm.new(create_params).save
    end

    it "saves the root model" do
      User.count.should == 1
    end

    it "saves the nested models" do
      User.first.addresses.count.should == 2
    end
  end

  context "when updating records" do
    subject { AutomatedRegistrationForm.new(update_params) }

    before do
      u = User.create!(
        :name                   => create_params[:name],
        :social_security_number => create_params[:social_security_number]
      )
      Address.create!(
        create_params[:addresses_attributes]["0"].merge(:user_id => u.id)
      )
      Address.create!(
        create_params[:addresses_attributes]["1"].merge(:user_id => u.id)
      )
    end

    context "record counts" do
      specify do
        lambda { subject.save }.should_not change(User, :count)
      end

      specify do
        lambda { subject.save }.should_not change(Address, :count)
      end
    end

    context "record attributes" do
      before do
        subject.save
      end

      specify do
        User.last.name.should == update_params[:name]
      end

      specify do
        User.last.social_security_number.should_not == update_params[:social_security_number]
      end

      specify do
        User.last.addresses.first.address1.should ==
          update_params[:addresses_attributes]["0"][:address1]
      end

      specify do
        User.last.addresses.first.alarm_code.should_not ==
          update_params[:addresses_attributes]["0"][:alarm_code]
      end
    end

  end
end
