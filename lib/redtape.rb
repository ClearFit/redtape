require "redtape/version"
require "redtape/model_factory"
require "redtape/populator/abstract"
require "redtape/populator/root"
require "redtape/populator/has_many"
require "redtape/populator/has_one"

require 'active_model'
require 'active_support/core_ext/class/attribute'

require 'active_record'

require 'forwardable'

module Redtape

  class DuelingBanjosError < StandardError; end
  class WhitelistViolationError < StandardError; end

  class Form
    extend Forwardable
    extend ActiveModel::Naming
    include ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations

    def_delegator :@factory, :model

    def initialize(controller, args = {})
      if controller.respond_to?(:populate_individual_record) && args[:whitelisted_attrs]
        fail DuelingBanjosError, "Redtape::Form does not accept both  #{controller.class}#populate_individual_record and the 'whitelisted_attrs' argument"
      end

      @factory = ModelFactory.new(factory_args_for(controller, args))
    end

    # Forms are never themselves persisted
    def persisted?
      false
    end

    def valid?
      model = @factory.populate_model
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
            @factory.save!
          end
        rescue ActiveRecord::RecordInvalid
          # This shouldn't even happen with the #valid? above.
        end
      else
        false
      end
    end

    private

    def factory_args_for(controller, args)
      args.dup.merge(
        :attrs => controller.params,
        :controller => controller
      )
    end
  end
end
