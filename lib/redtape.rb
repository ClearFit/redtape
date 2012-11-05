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

    def models_correct
      @@model_accessors.each do |accessor|
        begin
          model = send(accessor)
          unless model.valid?
            model.errors.each do |k, v|
              errors.add(k, v)
            end
          end
        rescue
        end
      end
    end

    # Forms are never themselves persisted
    def persisted?
      false
    end

    def save
      populate
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
      fail NotImplementedError, "Implement populate in your subclass"
    end
  end
end
