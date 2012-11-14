require 'spec_helper'

context "when #populate is not defined in the subclass" do
  context "the default implementation" do
    it "uses the value(s) passed to validate_and_save to locate the model params to use for population"
    it "looks up the classified name for the symbol passes to validate_and_saves"
  end
end
