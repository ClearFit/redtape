require "redtape/version"

require 'active_model'
require 'active_support/core_ext/class/attribute'

module Redtape
  class Form
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    ATTRIBUTES_KEY_REGEXP = /^(.+)_attributes$/

    class_attribute :model_accessor
    attr_reader     :params

    validate        :models_correct

    def self.validates_and_saves(accessor)
      attr_reader accessor
      self.model_accessor = accessor
    end

    def self.nested_accessible_attrs(attrs = {})
    end

    def initialize(attrs = {})
      @params = attrs
    end

    def models_correct
      model = populate(params, self.class.model_accessor)
      instance_variable_set("@#{self.class.model_accessor}", model)
      begin
        if model.invalid?
          own_your_errors_in(model)
        end
      rescue NoMethodError => e
        fail NoMethodError, "#{self.class} is missing 'validates_and_saves :#{model_accessor}': #{e}"
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
      model = send(self.class.model_accessor)
      model.save
    end

    def populate(params_subset, association_name)
      model_class = association_name.to_s.singularize.camelize.constantize
      model =
        if params_subset[:id]
          model_class.send(:find, params_subset[:id])
        else
          model_class.new
        end

      # #merge! didn't work here....
      model.attributes = model.attributes.merge(
        params_for_current_nesting_level_only(params_subset)
      )

      params_subset.each do |key, value|
        next unless key =~ ATTRIBUTES_KEY_REGEXP
        nested_association_name = $1
        # TODO: handle has_one
        # TODO :handle belongs_to

        children =
          if value.keys.all? { |k| k =~ /^\d+$/ }
            value.map { |_, has_many_attrs|
              populate(has_many_attrs, nested_association_name)
            }
          end
        binding.pry

        # nested_association_name is already singular or plural as appropriate
        model.send("#{nested_association_name}=", children)
      end

      model
    end

    private

    def params_for_current_nesting_level_only(params_subset)
      params_subset.dup.reject { |_, v| v.is_a? Hash }
    end

    def own_your_errors_in(model)
      model.errors.each do |k, v|
        errors.add(k, v)
      end
    end

  end
end
