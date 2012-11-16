require "redtape/version"

require 'active_model'
require 'active_support/core_ext/class/attribute'

require 'active_record'

module Redtape
  class Form
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    ATTRIBUTES_KEY_REGEXP = /^(.+)_attributes$/

    class_attribute   :model_accessor
    attr_reader       :params

    validate          :models_correct


    def self.validates_and_saves(accessor)
      attr_reader accessor
      self.model_accessor = accessor
    end

    def initialize(attrs = {})
      @params = attrs
      @updated_records = []
      @new_records = []
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

    # Forms are never themselves persisted
    def persisted?
      false
    end

    def save
      if valid?
        begin
          ActiveRecord::Base.transaction do
            persist!
            @updated_records.each(&:save!)
          end
        rescue
          # TODO: This feels so wrong...
        end
      else
        false
      end
    end

    def persist!
      model = send(self.class.model_accessor)
      model.save
    end

    def populate(attributes, model)
      add_attributes_to(model, :attributes => attributes)

      attributes.each do |key, value|
        next unless has_many_association_attrs?(key)

        # TODO: handle has_one
        # TODO :handle belongs_to
        populate_has_many(
          :in_association => association_name_in(key),
          :for_model      => model,
          :using          => has_many_attrs_array_from(value)
        )
      end

      model
    end

    private

    def has_many_attrs_array_from(fields_for_hash)
      fields_for_hash.values.clone
    end

    def has_many_association_attrs?(key)
      key =~ ATTRIBUTES_KEY_REGEXP
    end

    def association_name_in(key)
      ATTRIBUTES_KEY_REGEXP.match(key)[1]
    end

    def params_for_current_nesting_level_only(params_subset)
      params_subset.dup.reject { |_, v| v.is_a? Hash }
    end

    def own_your_errors_in(model)
      model.errors.each do |k, v|
        errors.add(k, v)
      end
    end

    def nested_model_instance_given(args = {})
      params_subset, association_name = args.values_at(:params, :association_name)

      model_class = association_name.to_s.singularize.camelize.constantize
      if params_subset[:id]
        model_class.send(:find, params_subset[:id])
      else
        model_class.new
      end
    end

    def add_attributes_to(model, args = {})
      # #merge! didn't work here....
      model.attributes = model.attributes.merge(
        params_for_current_nesting_level_only(args[:attributes])
      )
    end

    def find_or_create_model
      model_class = self.class.model_accessor.to_s.camelize.constantize
      if params[:id]
        model_class.send(:find, params[:id])
      else
        model_class.new
      end
    end

    def before_validation
      @updated_records.clear
      @new_records.clear

      model = find_or_create_model
      populate(params, model)

      instance_variable_set("@#{self.class.model_accessor}", model)
    end

    def populate_has_many(args = {})
      model, association_name, has_many_attrs_array = args.values_at(:for_model, :in_association, :using)

      association = model.send(association_name)

      children = association.map do |child_model|
        update_attrs = has_many_attrs_array.find { |a| a[:id] == child_model.id }
        has_many_attrs_array.delete(update_attrs)
        populate(update_attrs, child_model)
        @updated_records << child_model
      end

      has_many_attrs_array.each do |new_record_attrs|
        new_nested_model = populate(new_record_attrs, association.build)
        @new_records << new_nested_model
        association.send("<<", new_nested_model)
      end
    end
  end
end
