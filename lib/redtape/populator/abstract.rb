module Redtape
  module Populator
    class Abstract
      attr_reader :association_name, :model, :pending_attributes, :parent, :data_mapper

      def initialize(args = {})
        @model              = args[:model]
        @association_name   = args[:association_name]
        @pending_attributes = args[:attrs]
        @parent             = args[:parent]
        @data_mapper        = args[:data_mapper]
      end

      def call
        populate_model_attributes(model, pending_attributes)

        if model.new_record?
          assign_to_parent
        end
      end

      protected

      def assign_to_parent
        fail NotImplementedError, "You have to implement this in your subclass"
      end

      private

      def populate_model_attributes(model, attributes)
        msg_target =
          if data_mapper.respond_to?(:populate_individual_record)
            data_mapper
          else
            self
          end
        msg_target.send(
          :populate_individual_record,
          model,
          attributes
        )
      end

      def populate_individual_record(record, attrs)
        # #merge! didn't work here....
        record.attributes = record.attributes.merge(attrs)
      end
    end
  end
end
