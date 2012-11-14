require 'spec_helper'

describe Redtape::Form do
  context "simulating a nested form from the view for a User with many Addresses" do
    context "where the Address form fields adhere to Address column names" do
      subject { UserWithAddressesRegistrationForm.new(fake_rails_params) }

      let(:fake_rails_params) {
        HashWithIndifferentAccess.new(
          :first_name => "Evan",
          :last_name => "Light",
          :addresses_attributes => {
            "0" => {
              :address1 => "123 Foobar way",
              :city     => "Foobar",
              :state    => "MN",
              :zipcode  => "12345"
            },
            "1" => {
              :address1 => "124 Foobar way",
              :city     => "Foobar",
              :state    => "MN",
              :zipcode  => "12345"
            }
          }
        )
      }

      before do
        subject.save
      end

      specify { subject.user.addresses.count.should == 2 }
    end
  end
end
