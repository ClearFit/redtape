require "redtape/version"
require "redtape/model_factory"
require "redtape/populator/abstract"
require "redtape/populator/root"
require "redtape/populator/has_many"
require "redtape/populator/has_one"

require 'active_model'
require 'active_support/core_ext/class/attribute'

require 'active_record'

module Redtape

  class DuelingBanjosError < StandardError; end
  class WhitelistViolationError < StandardError; end

  class Form
    extend ActiveModel::Naming
    include ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attr_reader :model_accessor

    def initialize(populator, args = {})
      if populator.respond_to?(:populate_individual_record) && args[:whitelisted_attrs]
        fail DuelingBanjosError, "Redtape::Form does not accept both  #{populator.class}#populate_individual_record and the 'whitelisted_attrs' argument"
      end

      @model_accessor       =
        args[:whitelisted_attrs].try(:keys).try(:first) ||
        args[:model_accessor] ||
        default_model_accessor_from(populator)

      @factory = ModelFactory.new(factory_args_for(populator, args))
    end

    # Forms are never themselves persisted
    def persisted?
      false
    end

    def valid?
      model = @factory.populate_model
      instance_variable_set("@#{@model_accessor}", model)
      valid = model.valid?

      # @errors comes from ActiveModel::Validations. This may not
      # be a legit hook.
      @errors = model.errors

      valid
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

    def respond_to?(method, instance_method = false)
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

    def factory_args_for(populator, args)
      factory_args = {
        :model_accessor => model_accessor,
        :attrs          => populator.params
      }
      addl_args =
        if args[:whitelisted_attrs] && populator.respond_to?(:populate_individual_record)
          fail ArgumentError, "Expected either :data_mapper to respond_to #populate_individual_record or :whitelisted_attrs"
        elsif populator.respond_to?(:populate_individual_record)
          { :data_mapper => populator }
        elsif args[:whitelisted_attrs]
          {
            :whitelisted_attrs => args[:whitelisted_attrs]
          }
        else
          {}
        end
      factory_args.merge(addl_args)
    rescue
      binding.pry
    end
  end
end
