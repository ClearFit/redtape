require 'spec_helper'

describe Redtape::AttributeWhitelist do
  subject { Redtape::AttributeWhitelist.new(:user => [:name, {:addresses => [:address1]}]) }

  context "#allows?" do
    specify { subject.allows?(:association_name => :user, :attr => :name).should be_true }
    specify { subject.allows?(:association_name => :user, :attr => :social_security_number).should be_false }
    specify { subject.allows?(:association_name => :addresses, :attr => :address1).should be_true }
    specify { subject.allows?(:association_name => :addresses, :attr => :alarm_code).should be_false }
  end

  context "#scoped_whitelisted_attrs_for" do
    specify { subject.send(:whitelisted_attrs_for, :user).should == [:name] }
    specify { subject.send(:whitelisted_attrs_for, :addresses).should == [:address1] }
    specify { subject.send(:whitelisted_attrs_for, :addresses, {:addresses => [:address1]}).should == [:address1] }
  end
end
