require "redtape/version"

require 'active_model'
require 'active_support/core_ext/class/attribute'

module Redtape
  class Form
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

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
      populate
      begin
        model = send(model_accessor)
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

    def populate
      model_class = self.class.model_accessor.to_s.camelize.constantize
      root =
        if params[:id]
          model_class.send(:find, params[:id])
        else
          model_class.new
        end

      # #merge! didn't work here....
      root.attributes = root.attributes.merge(root_level_params)

      instance_variable_set("@#{model_accessor}", root)

    end

    private

    def root_level_params
      @root_level_params ||= params.dup.reject { |_, v| v.is_a? Hash }
    end

    def own_your_errors_in(model)
      model.errors.each do |k, v|
        errors.add(k, v)
      end
    end

  end
end
