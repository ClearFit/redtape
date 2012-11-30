module Redtape
  class ModelFactory
    attr_reader :model_accessor, :records_to_save, :model, :data_mapper, :whitelisted_attrs, :attrs

    def initialize(args = {})
      @attrs             = args[:attrs].first.last
      @whitelisted_attrs = args[:whitelisted_attrs]
      @data_mapper       = args[:data_mapper]
      @model_accessor    = args[:model_accessor]
      @records_to_save   = []
    end

    def populate_model
      @model = find_or_create_root_model_from(attrs)

      populators = [ Populator::Root.new(root_populator_args) ]
      populators.concat(
        create_populators_for(model, attrs).flatten
      )

      populators.each do |p|
        p.call
      end

      @model
    end

    private

    def root_populator_args
      root_populator_args = {
        :model       => model,
        :attrs       => params_for_current_scope(attrs)
      }.tap do |r|
        if data_mapper
          r[:data_mapper] = data_mapper
        elsif whitelisted_attrs.present?
          r[:whitelisted_attrs] = whitelisted_attrs
        end
      end
    end

    def find_associated_model(attrs, args = {})
      case args[:with_macro]
      when :has_many
        args[:on_association].find(attrs[:id])
      when :has_one
        args[:on_model].send(args[:for_association_name])
      end
    end

    def find_or_create_root_model_from(params)
      model_class = model_accessor.to_s.camelize.constantize
      if params[:id]
        model_class.send(:find, params[:id])
      else
        model_class.new
      end
    end

    def create_populators_for(model, attributes)
      attributes.each_with_object([]) do |key_value, association_populators|
        next unless key_value[1].is_a?(Hash)

        key, value       = key_value
        macro            = macro_for_attribute_key(key)
        associated_attrs =
          case macro
          when :has_many
            value.values
          when :has_one
            [value]
          end

        associated_attrs.inject(association_populators) do |populators, record_attrs|
          assoc_name = find_association_name_in(key)
          current_scope_attrs = params_for_current_scope(record_attrs)

          associated_model = find_or_initialize_associated_model(
            current_scope_attrs,
            :for_association_name => assoc_name,
            :on_model             => model,
            :with_macro           => macro
          )

          populator_class = "Redtape::Populator::#{macro.to_s.camelize}".constantize

          populator_args = {
            :model                => associated_model,
            :association_name     => assoc_name,
            :attrs                => current_scope_attrs,
            :parent               => model
          }
          if data_mapper
            populator_args[:data_mapper] = data_mapper
          elsif whitelisted_attrs.present?
            populator_args[:whitelisted_attrs] = scoped_whitelisted_attrs_for(assoc_name)
          end

          populators << populator_class.new(populator_args)
          populators.concat(
            create_populators_for(associated_model, record_attrs)
          )
        end
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
      association_reflection.macro
    end

    def scoped_whitelisted_attrs_for(assoc_name)
      root_whitelisted_attrs = whitelisted_attrs.values.first
      whitelisted_attrs_for(assoc_name, root_whitelisted_attrs)
    end

    # Locate whitelisted attributes for the supplied association name
    def whitelisted_attrs_for(assoc_name, whitelisted_attrs)
      whitelisted_attrs.find do |whitelisted_attr|
        next unless whitelisted_attr.is_a?(Hash)

        if whitelisted_attr.keys.first == assoc_name
          return whitelisted_attr
        end

        whitelisted_attrs_for(assoc_name, whitelisted_attr)
      end
    end

    def params_for_current_scope(attrs)
      attrs.dup.reject { |_, v| v.is_a? Hash }
    end

    ATTRIBUTES_KEY_REGEXP = /^(.+)_attributes$/

    def has_many_association_attrs?(key)
      key =~ ATTRIBUTES_KEY_REGEXP
    end

    def find_association_name_in(key)
      ATTRIBUTES_KEY_REGEXP.match(key)[1]
    end
  end
end
