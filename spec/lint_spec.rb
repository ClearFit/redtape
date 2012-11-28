require 'spec_helper'

class RegistrationController
  def params
    {
      :user => {
        :name => "Ohai ohai"
      }
    }
  end
end

require 'minitest/unit'

describe "my looks like model class" do
  include ActiveModel::Lint::Tests
  include MiniTest::Assertions

  subject { Redtape::Form.new(RegistrationController.new, :model_accessor => :user) }

  def model
    subject
  end

  # to_s is to support ruby-1.9
  ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
    example m.gsub('_',' ') do
      send m
    end
  end

end
