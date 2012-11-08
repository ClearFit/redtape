require "redtape/version"

require 'active_model'

module Redtape
  class Form
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attr_accessor :model_accessors

    validate :models_correct

    def self.validates_and_saves(*args)
      attr_accessor *args
      @@model_accessors = args
    end

    def initialize(attrs = {})
      attrs.each do |k, v|
        send("#{k}=", v)
      end
    end

    def models_correct
      populate
      @@model_accessors.each do |accessor|
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
      @@model_accessors.each do |accessor|
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

    private

    def own_your_errors_in(model)
      model.errors.each do |k, v|
        errors.add(k, v)
      end
    end
  end
end
