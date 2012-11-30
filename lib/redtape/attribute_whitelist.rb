module Redtape
  class AttributeWhitelist
    attr_reader :whitelisted_attrs

    def initialize(whitelisted_attrs)
      @whitelisted_attrs = whitelisted_attrs
    end

    def top_level_name
      whitelisted_attrs.try(:keys).try(:first)
    end

    def allows?(args = {})
      allowed_attrs = whitelisted_attrs_for(args[:association_name]) || []
      allowed_attrs << :id
      allowed_attrs.include?(args[:attr])
    end

    private

    # Locate whitelisted attributes for the supplied association name
    def whitelisted_attrs_for(assoc_name, attr_hash = whitelisted_attrs)
      attr_hash.values.first.find { |whitelisted_attr|
        if assoc_name == attr_hash.keys.first
          return attr_hash.values.first.reject { |v| v.is_a? Hash }
        end

        next unless whitelisted_attr.is_a?(Hash)
        whitelisted_attrs_for(assoc_name, whitelisted_attr)
      }.values.first
    end
  end

  class NullAttrWhitelist
    def top_level_name
      nil
    end

    def present?
      false
    end

    def nil?
      true
    end

    def allows?(args = {})
      false
    end
  end
end
