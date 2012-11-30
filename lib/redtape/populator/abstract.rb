module Redtape
  module Populator
    class Abstract
      attr_reader :association_name, :model, :pending_attributes, :parent, :data_mapper, :attr_whitelist

      def initialize(args = {})
        @model              = args[:model]
        @association_name   = args[:association_name]
        @pending_attributes = args[:attrs]
        @parent             = args[:parent]
        @data_mapper        = args[:data_mapper]
        @attr_whitelist     = args[:attr_whitelist]
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
          if data_mapper && data_mapper.respond_to?(:populate_individual_record)
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
        assert_against_whitelisted(attrs.keys)

        # #merge! didn't work here....
        record.attributes = record.attributes.merge(attrs)
      end

      def assert_against_whitelisted(attrs)
        return unless attr_whitelist.present?
        return if model.new_record?

        failed_attrs = []
        attrs.each do |a|
          p "unless attr_whitelist.allows?(:association_name => #{association_name}, :attr => #{a})"
          unless attr_whitelist.allows?(:association_name => association_name, :attr => a)
            failed_attrs << %{"#{association_name}##{a}"}
          end
        end

        if failed_attrs.present?
          fail WhitelistViolationError, "Form supplied non-whitelisted attrs #{failed_attrs.join(", ")}"
        end
      end
    end
  end
end
