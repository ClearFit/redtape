module Redtape
  module Populator
    class Base
      attr_reader :association_name, :model, :pending_attributes, :parent, :data_mapper

      def initialize(model, association_name, pending_attributes, parent, data_mapper)
        @model = model
        @association_name = association_name
        @pending_attributes = pending_attributes
        @parent = parent
        @data_mapper = data_mapper
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
