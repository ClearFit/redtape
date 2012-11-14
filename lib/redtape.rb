require "redtape/version"

require 'active_model'
require 'active_support/core_ext/class/attribute'

module Redtape
  class Form
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    validate :models_correct
    class_attribute :model_accessors

    def self.validates_and_saves(*args)
      attr_accessor *args
      self.model_accessors = args
    end

    def initialize(attrs = {})
      attrs.each do |k, v|
        send("#{k}=", v)
      end

      populate
    end

    def models_correct
      self.class.model_accessors.each do |accessor|
        begin
          model = send(accessor)
          if model.invalid?
            own_your_errors_in(model)
          end
        rescue NoMethodError => e
          fail NoMethodError, "#{self.class} is missing 'validates_and_saves :#{accessor}': #{e}"
        end
      end
    end

    # Forms are never themselves persisted
    def persisted?
      false
    end

    def save
      if valid?
        persist!
      else
        false
      end
    end

    def persist!
      self.class.model_accessors.each do |accessor|
        model = send(accessor)
        unless model.save
          return false
        end
      end
      true
    end

    def populate
      fail NotImplementedError, "Implement #populate in your subclass"
    end

    def assign_values(attrs = {})
      attrs.each do |k, v|
        send("#{k}=", v)
      end

      assign
      self
    end

    private

    def own_your_errors_in(model)
      model.errors.each do |k, v|
        errors.add(k, v)
      end
    end
  end
end
