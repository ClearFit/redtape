require "redtape/version"
require "redtape/model_factory"

require 'active_model'
require 'active_support/core_ext/class/attribute'

require 'active_record'

module Redtape
  class Form
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    validate          :models_correct

    def initialize(finder_and_populator)
      @finder_and_populator = finder_and_populator
      @factory              = ModelFactory.new(finder_and_populator)
    end

    # Forms are never themselves persisted
    def persisted?
      false
    end

    def save
      if valid?
        begin
          ActiveRecord::Base.transaction do
            @factory.model.save!
            @factory.records_to_save.each(&:save!)
          end
        rescue ActiveRecord::RecordInvalid
          # This shouldn't even happen with the #valid? above.
        end
      else
        false
      end
    end

    private

    def before_validation
      model = @factory.populate_model
      instance_variable_set("@#{@finder_and_populator.model_accessor}", model)
    end

    def models_correct
      before_validation

      model = instance_variable_get("@#{@finder_and_populator.model_accessor}")
      begin
        if model.invalid?
          own_your_errors_in(model)
        end
      rescue NoMethodError => e
        fail NoMethodError, "#{self.class} is missing 'validates_and_saves :#{@finder_and_populator.model_accessor}': #{e}"
      end
    end

    # TODO: Do we even needs this if each model has its own errors and the caller is using forms_for and fields_for?
    def own_your_errors_in(model)
      model.errors.each do |k, v|
        errors.add(k, v)
      end
    end
  end
end
