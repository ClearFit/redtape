require 'spec_helper'

class UsersController; end

describe "Using the default ModelFactory" do
  let(:create_params) {
    HashWithIndifferentAccess.new(
      :user => {
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
      }
    )
  }

  let(:update_params) {
    HashWithIndifferentAccess.new(
      :user => {
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
      }
    )
  }

  context "when creating records" do
    let(:controller_stub) {
      UsersController.new.tap { |c| c.stub(:params => create_params) }
    }

    before do
      Redtape::Form.new(controller_stub).save
    end

    it "saves the root model" do
      User.count.should == 1
    end

    it "saves the nested models" do
      User.first.addresses.count.should == 2
    end
  end

  context "when updating records" do
    let(:controller_stub) {
      UsersController.new.tap { |c| c.stub(:params => update_params) }
    }

    subject { Redtape::Form.new(controller_stub) }

    before do
      params = create_params[:user]
      u = User.create!(
        :name                   => params[:name],
        :social_security_number => params[:social_security_number]
      )
      Address.create!(
        params[:addresses_attributes]["0"].merge(:user_id => u.id)
      )
      Address.create!(
        params[:addresses_attributes]["1"].merge(:user_id => u.id)
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
        User.last.name.should == update_params[:user][:name]
      end

      specify do
        User.last.social_security_number.should_not == update_params[:user][:social_security_number]
      end

      specify do
        User.last.addresses.first.address1.should ==
          update_params[:user][:addresses_attributes]["0"][:address1]
      end

      specify do
        User.last.addresses.first.alarm_code.should_not ==
          update_params[:user][:addresses_attributes]["0"][:alarm_code]
      end
    end

  end

  context "User has_one PhoneNumber" do
    let(:create_params) {
      HashWithIndifferentAccess.new(
        :user => {
          :name => "Evan Light",
          :phone_number_attributes => {
            :country_code => "1",
            :area_code    => "123",
            :number       => "456-7890"
          }
        }
      )
    }

    let(:controller_stub) {
      UsersController.new.tap { |c| c.stub(:params => create_params) }
    }

    subject { Redtape::Form.new(controller_stub) }

    specify do
      count = User.count
      subject.save
      User.count.should == count + 1
    end

    specify do
      count = PhoneNumber.count
      subject.save
      PhoneNumber.count.should == count + 1
    end

  end
end
