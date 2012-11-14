require "redtape/version"

require 'active_model'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'

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

      model_class = model_accessors.first.to_s.camelize.constantize

      column_names = model_class.arel_table.columns.map { |c| ":#{c.name}" } - [":id"]

      p column_names
      instance_eval <<-EVAL
        attr_accessor #{column_names.join(", ")}
      EVAL

      model_class.reflect_on_all_associations(:has_many).each do |association|
        instance_eval <<-EVAL
          attr_accessor :#{association.table_name}_attributes
        EVAL
      end

      [:has_one, :belongs_to].each do |assoc_type|
        nested_params_keys = model_class.reflect_on_all_associations(assoc_type).map { |a|
          ":#{a.table_name.singularize}_attributes"
        }
        instance_eval <<-EVAL
          attr_accessor #{nested_params_keys.join(", ")}
        EVAL
      end
    end

    def self.nested_accessible_attrs(attrs = {})
    end

    def initialize(attrs = {})
      attrs.each do |attr_name, v|
        send("#{attr_name}=", v)
      end
    end

    def models_correct
      populate
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
#      fail NotImplementedError, "Implement #populate in your subclass"
    end

    private

    def own_your_errors_in(model)
      model.errors.each do |k, v|
        errors.add(k, v)
      end
    end
  end
end
