module Redtape
  class ModelFactory
    attr_reader :top_level_name, :records_to_save, :model, :controller, :attr_whitelist, :attrs

    def initialize(args = {})
      assert_inputs(args)

      @attrs             = args[:attrs]
      @attr_whitelist    = NullAttrWhitelist.new
      @controller        = args[:controller]
      @records_to_save   = []
      @top_level_name    =
        @attr_whitelist.top_level_name ||
        args[:top_level_name] ||
        default_top_level_name_from(controller)
      if args[:whitelisted_attrs]
        @attr_whitelist  = AttributeWhitelist.new(args[:whitelisted_attrs])
      end
    end

    def populate_model
      @model = find_or_create_root_model

      populators = [ Populator::Root.new(root_populator_args) ]
      populators.concat(
        create_populators_for(model, attrs.values.first).flatten
      )

      populators.each do |p|
        p.call
      end

      violations = populators.map(&:whitelist_failures).flatten
      if violations.present?
        errors = violations.join(", ")
        fail WhitelistViolationError, "Form supplied non-whitelisted attrs #{errors}"
      end

      @model
    end

    def save!
      model.save!
      records_to_save.each(&:save!)
    end

    private

    def default_top_level_name_from(controller)
      if controller.class.to_s =~ /(\w+)Controller/
        $1.singularize.downcase.to_sym
      end
    end

    def root_populator_args
      root_populator_args = {
        :model            => model,
        :attrs            => params_for_current_scope(attrs.values.first),
        :association_name => attrs.keys.first
      }.tap do |r|
        if attr_whitelist.present? && controller.respond_to?(:populate_individual_record)
          fail ArgumentError, "Expected either controller to respond_to #populate_individual_record or :whitelisted_attrs but not both"
        elsif controller.respond_to?(:populate_individual_record)
          r[:data_mapper] = controller
        elsif attr_whitelist
          r[:attr_whitelist] = attr_whitelist
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

    def find_or_create_root_model
      model_class = top_level_name.to_s.camelize.constantize
      root_object_id = attrs.values.first[:id]
      if root_object_id
        model_class.send(:find, root_object_id)
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
          if controller.respond_to?(:populate_individual_record) && attr_whitelist.present?
            fail ArgumentError, "Expected either controller to respond_to #populate_individual_record or :whitelisted_attrs but not both"
          elsif controller.respond_to?(:populate_individual_record)
            populator_args[:data_mapper] = controller
          elsif attr_whitelist
            populator_args[:attr_whitelist] = attr_whitelist
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
          :on_association => association
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

    def assert_inputs(args)
      if args[:top_level_name] && args[:whitelisted_attrs].present?
        fail ArgumentError, ":top_level_name is redundant as it is already present as the key in :whitelisted_attrs"
      end
    end
  end
end
