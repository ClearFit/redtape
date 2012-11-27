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

    attr_reader :model_accessor

    def initialize(populator, args = {})
      @model_accessor       = args[:model_accessor] || default_model_accessor_from(populator)
      @factory              = ModelFactory.new(populator, model_accessor)
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

    def method_missing(*args)
      if args[0] == send(:model_accessor)
        # The factory owns the model instance
        @factory.model
      else
        super
      end
    end

    def respond_to?(method, instance_method)
      if method == send(:model_accessor)
        true
      else
        super
      end
    end

    private

    def default_model_accessor_from(populator)
      if populator.class.to_s =~ /(\w+)Controller/
        $1.singularize.downcase.to_sym
      end
    end

    def before_validation
      model = @factory.populate_model
      instance_variable_set("@#{model_accessor}", model)
    end

    def models_correct
      before_validation

      model = instance_variable_get("@#{model_accessor}")
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
