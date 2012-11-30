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
      allowed_attrs = allowed_attrs.map(&:to_s)
      allowed_attrs << "id"
      allowed_attrs.include?(args[:attr].to_s)
    end

    private

    # Locate whitelisted attributes for the supplied association name
    def whitelisted_attrs_for(assoc_name, attr_hash = whitelisted_attrs)
      if assoc_name.to_s == attr_hash.keys.first.to_s
        return attr_hash.values.first.reject { |v| v.is_a? Hash }
      end

      scoped_whitelisted_attrs = attr_hash.values.first
      scoped_whitelisted_attrs.reject { |v|
        !v.is_a? Hash
      }.find { |v|
        whitelisted_attrs_for(assoc_name, v)
      }.try(:values).try(:first)
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
