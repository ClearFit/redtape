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

      # Find or create the root model then populate it
      @model = find_or_create_root_model_from(params)

      populators = [
        Populator::Root.new(
          @model,
          nil,
          params_for_current_scope_only(params),
          nil,
          @populator
        )
      ]
      populators.concat(
        create_populators_for(model, params).flatten
      )

      populators.each do |p|
        p.call
      end

      @model
    end

    private

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

    def create_populators_for(model, attributes)
      attributes.each_with_object([]) do |kv, association_populators|
        key, value = kv[0], kv[1]

        next unless refers_to_association?(value)

        macro = macro_for_attribute_key(key)
        association_populators.concat(
          case macro
          when :has_many
            value.inject([]) do |has_many_populators, kv|
              record_attrs = kv[1]
              assoc_name = find_association_name_in(key)
              current_scope_attrs = params_for_current_scope_only(record_attrs)
              associated_model = find_or_initialize_associated_model(
                record_attrs,
                :for_association_name => assoc_name,
                :on_model             => model,
                :with_macro           => macro
              )
              has_many_populators << Populator::HasMany.new(
                associated_model,
                assoc_name,
                current_scope_attrs,
                model,
                @populator
              )
              has_many_populators.concat(
               create_populators_for(associated_model, record_attrs)
              )
              has_many_populators
            end
          when :has_one
            assoc_name = find_association_name_in(key)
            record_attrs = params_for_current_scope_only(value)
            associated_model = find_or_initialize_associated_model(
              record_attrs,
              :for_association_name => assoc_name,
              :on_model             => model,
              :with_macro           => macro
            )
            Array(
              Populator::HasOne.new(
                associated_model,
                assoc_name,
                record_attrs,
                model,
                @populator
              )
            ).concat(
              create_populators_for(associated_model, record_attrs)
            )
          when :belongs_to
            fail "Implement me"
          else
            fail "How did you get here anyway?"
          end
        )
      end
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

    def macro_for_attribute_key(key)
      association_name = find_association_name_in(key).to_sym
      association_reflection = model.class.reflect_on_association(association_name)
      macro = association_reflection.macro
    end

    def refers_to_association?(value)
      value.is_a?(Hash)
    end

    def params_for_current_scope_only(attrs)
      attrs.dup.reject { |_, v| v.is_a? Hash }
    end

    ATTRIBUTES_KEY_REGEXP = /^(.+)_attributes$/

    def has_many_association_attrs?(key)
      key =~ ATTRIBUTES_KEY_REGEXP
    end

    def find_association_name_in(key)
      ATTRIBUTES_KEY_REGEXP.match(key)[1]
    end

    def has_many_attrs_array_from(fields_for_hash)
      fields_for_hash.values.clone
    end
  end
end
