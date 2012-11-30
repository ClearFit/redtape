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

    context "with attributes that were not whitelisted" do

      subject {
        Redtape::Form.new(controller_stub, :whitelisted_attrs => {
          :user => [
            :name,
            {
              :addresses => [
                :address1,
                :address2,
                :city,
                :state,
                :zipcode,
              ]
            }
          ]
        })
      }

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

      specify do
        lambda { subject.save }.should raise_error(Redtape::WhitelistViolationError)
      end

      specify do
        begin
          subject.save
        rescue
          expect($!.to_s).to match(/social_security_number/)
        end
      end

      specify do
        begin
          subject.save
        rescue
          expect($!.to_s).to match(/alarm_code/)
        end
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
