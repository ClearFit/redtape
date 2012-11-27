module Redtape
  class ModelFactory
    attr_reader :model_accessor, :records_to_save, :model

    def initialize(finder_and_populator)
      @finder_and_populator = finder_and_populator
      @model_accessor = finder_and_populator.model_accessor
      @records_to_save = []
    end

    def populate_model
      params = @finder_and_populator.params[@model_accessor]
      @model = find_or_create_root_model_from(params)
      populate(@model, params)
    end

    protected

    # API hook to map request parameters (truncated from the attributes for this
    # record on down) onto the provided record instance.
    def populate_individual_record(record, attrs)
      # #merge! didn't work here....
      record.attributes = record.attributes.merge(attrs)
    end

    # API hook used to look up an existing record given its AssociationProxy
    # and all of the form parameters relevant to this record.
    def find_associated_model(attrs, args = {})
      case args[:with_macro]
      when :has_many
        args[:on_association].find(attrs[:id])
      when :has_one
        args[:on_model].send(args[:for_association_name])
      end
    end

    private

    # Factory method for root object
    def find_or_create_root_model_from(params)
      model_class = model_accessor.to_s.camelize.constantize
      if params[:id]
        model_class.send(:find, params[:id])
      else
        model_class.new
      end
    end

    def populate(model, attributes)
      populate_individual_record(
        model,
        params_for_current_nesting_level_only(attributes)
      )

      attributes.each do |key, value|
        next unless refers_to_association?(value)

        association_name = association_name_in(key).to_sym
        association_reflection = model.class.reflect_on_association(association_name)
        macro = association_reflection.macro

        associated_models_with_pending_updates =
          case macro
          when :has_many
            value.map do |_, record_attrs|
              [
                find_or_initialize_associated_model(
                  record_attrs,
                  :for_association_name => association_name_in(key),
                  :on_model             => model,
                  :with_macro           => macro
                ),
                record_attrs
              ]
            end
          when :has_one
            [
              [
                find_or_initialize_associated_model(
                  value,
                  :for_association_name => association_name_in(key),
                  :on_model             => model,
                  :with_macro           => macro
                ),
                value
              ]
            ]
          when :belongs_to
            fail "Implement me"
          else
            fail "How did you get here anyway?"
          end

        associated_models_with_pending_updates.each do |associated_model, update_attrs|
          if associated_model.new_record?
            case macro
            when :has_many
              model.send(association_name).send("<<", associated_model)
            when :has_one
              model.send("#{association_name}=", associated_model)
            end
          end

          populate_individual_record(
            associated_model,
            params_for_current_nesting_level_only(update_attrs)
          )
        end
      end

      model
    end

    def find_or_initialize_associated_model(attrs, args = {})
      association_name, macro, model = args.values_at(:for_association_name, :with_macro, :on_model)

      association = model.send(association_name)
      if attrs[:id]
        find_associated_model(
          attrs,
          :on_model => model,
          :with_macro => macro,
          :on_association => association,
        ).tap do |record|
          records_to_save << record
        end
      else
        case macro
        when :has_many
          model.send(association_name).build
        when :has_one
          model.send("build_#{association_name}")
        end
      end
    end

    def refers_to_association?(value)
      value.is_a?(Hash)
    end

    def params_for_current_nesting_level_only(attrs)
      attrs.dup.reject { |_, v| v.is_a? Hash }
    end

    ATTRIBUTES_KEY_REGEXP = /^(.+)_attributes$/

    def has_many_association_attrs?(key)
      key =~ ATTRIBUTES_KEY_REGEXP
    end

    def association_name_in(key)
      ATTRIBUTES_KEY_REGEXP.match(key)[1]
    end

    def has_many_attrs_array_from(fields_for_hash)
      fields_for_hash.values.clone
    end
  end
end
