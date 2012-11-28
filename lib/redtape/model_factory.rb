module Redtape
  class ModelFactory
    attr_reader :model_accessor, :records_to_save, :model

    def initialize(populator, model_accessor = nil)
      @populator = populator
      @model_accessor = model_accessor
      @records_to_save = []
    end

    def populate_model
      params = @populator.params[model_accessor]
      @model = find_or_create_root_model_from(params)
      populate(@model, params)
    end

    private

    def populate_individual_record(record, attrs)
      # #merge! didn't work here....
      record.attributes = record.attributes.merge(attrs)
    end

    def find_associated_model(attrs, args = {})
      case args[:with_macro]
      when :has_many
        args[:on_association].find(attrs[:id])
      when :has_one
        args[:on_model].send(args[:for_association_name])
      end
    end

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
      populate_model_attributes(model, attributes)

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

    def populate_model_attributes(model, attributes)
      msg_target =
        if @populator.respond_to?(:populate_individual_record)
          @populator
        else
          self
        end
      msg_target.send(
        :populate_individual_record,
        model,
        params_for_current_nesting_level_only(attributes)
      )
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
