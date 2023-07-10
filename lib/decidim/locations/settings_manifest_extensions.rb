# frozen_string_literal: true

module Decidim
  module Locations
    module SettingsManifestExtensions
      extend ActiveSupport::Concern

      include Decidim::AttributeObject::TypeMap

      included do
        types = remove_const("TYPES")
        const_set("TYPES", types.merge(float: { klass: Float, default: nil }).freeze)

        # Redefine the type inclusion validator
        _validators.reject! { |key, _| key == :type }
        _validate_callbacks.each do |callback|
          _validate_callbacks.delete(callback) if callback.raw_filter.attributes == [:type]
        end
        validates :type, inclusion: { in: const_get("TYPES").keys }
      end
    end
  end
end
