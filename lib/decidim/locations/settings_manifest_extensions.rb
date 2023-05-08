# frozen_string_literal: true

module Decidim
  module Locations
    module SettingsManifestExtensions
      extend ActiveSupport::Concern

      include Decidim::AttributeObject::TypeMap

      included do
        remove_const("TYPES")
        const_set("TYPES", {
          boolean: { klass: Boolean, default: false },
          integer: { klass: Integer, default: 0 },
          string: { klass: String, default: nil },
          float: { klass: Float, default: nil },
          text: { klass: String, default: nil },
          array: { klass: Array, default: [] },
          enum: { klass: String, default: nil },
          select: { klass: String, default: nil },
          scope: { klass: Integer, default: nil },
          time: { klass: Decidim::Attributes::TimeWithZone, default: nil }
        }.freeze)

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
