# frozen_string_literal: true

module Decidim
  module Locations
    # A form object to be represent a location.
    class LocationForm < Decidim::Form
      mimic :location

      attribute :deleted, Boolean, default: false
      attribute :address, String
      attribute :latitude, Float
      attribute :longitude, Float

      def to_param
        return id if id.present?

        "location-id"
      end
    end
  end
end
