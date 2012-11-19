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

    class_attribute   :model_accessor
    attr_reader       :params

    validate          :models_correct


    def self.validates_and_saves(accessor)
      attr_reader accessor
      self.model_accessor = accessor
    end

    def initialize(attrs = {}, args = { :factory_class => ModelFactory })
      @params = attrs
      @factory = args[:factory_class].new(self.class.model_accessor)
    end

    # Forms are never themselves persisted
    def persisted?
      false
    end

    def save
      if valid?
        begin
          ActiveRecord::Base.transaction do
            model = send(self.class.model_accessor)
            model.save!
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
      model = @factory.populate_model_using(params)
      instance_variable_set("@#{self.class.model_accessor}", model)
    end

    def models_correct
      before_validation

      model = instance_variable_get("@#{self.class.model_accessor}")
      begin
        if model.invalid?
          own_your_errors_in(model)
        end
      rescue NoMethodError => e
        fail NoMethodError, "#{self.class} is missing 'validates_and_saves :#{model_accessor}': #{e}"
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
