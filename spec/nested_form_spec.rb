require 'spec_helper'

class NestedFormController
  include NestedFormRedtape
end

describe Redtape::Form do
  subject { Redtape::Form.new(controller_stub, :model_accessor => :user) }

  let(:create_params) {
    HashWithIndifferentAccess.new(
      :user => {
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
      }
    )
  }

  context "Creating a user" do
    context "where simulating a nested form from the view for a User with many Addresses" do
      context "where the Address form fields adhere to Address column names" do
        let(:controller_stub) {
          NestedFormController.new.tap do |c|
            c.stub(:params).and_return(create_params)
          end
        }

        before do
          subject.save
        end

        specify { subject.user.addresses.count.should == 2 }
      end
    end
  end

  context "Updating a user who has addresses" do
    context "where simulating a nested form from the view for a User with many Addresses" do
      context "where the Address form fields adhere to Address column names" do
        before do
          params = create_params
          u = User.create!(:name => "#{params[:user][:first_name]} #{params[:user][:last_name]}")
          @address1 = Address.create!(
            params[:user][:addresses_attributes]["0"].merge(:user_id => u.id)
          )
          @address2 = Address.create!(
            params[:user][:addresses_attributes]["1"].merge(:user_id => u.id)
          )
        end

        let(:update_params) {
          HashWithIndifferentAccess.new(
            :user => {
              :id         => User.last.id,
              :first_name => "Evan",
              :last_name  => "Not-so-bright-light",
              :addresses_attributes => {
                "0" => {
                  :id       => @address1.id,
                  :address1 => "456 Foobar way",
                  :city     => "Foobar",
                  :state    => "MN",
                  :zipcode  => "12345"
                },
                "1" => {
                  :id       => @address2.id,
                  :address1 => "124 Foobar way",
                  :city     => "Foobar",
                  :state    => "MN",
                  :zipcode  => "12345"
                }
              }
            }
          )
        }

        let(:controller_stub) {
          NestedFormController.new.tap do |c|
            c.stub(:params).and_return(update_params)
          end
        }



        specify {
          lambda { subject.save }.should_not change(User, :count)
        }

        specify {
          lambda { subject.save }.should_not change(Address, :count)
        }

        specify {
          subject.save
          User.last.name.should ==
            "#{update_params[:user][:first_name]} #{update_params[:user][:last_name]}"
        }

        specify {
          subject.save
          User.last.addresses.first.address1.should ==
            update_params[:user][:addresses_attributes]["0"][:address1]
        }
      end
    end
  end
end
