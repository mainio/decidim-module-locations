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
      attribute :shape, String
      attribute :geojson, JSON

      validates :address, presence: true, if: ->(form) { !form.deleted && (form.latitude.blank? || form.longitude.blank?) }
      validates :latitude, :longitude, presence: true, if: ->(form) { !form.deleted && form.address.blank? }
      validate :json_validation, if: ->(form) { !form.deleted }

      def to_param
        return id if id.present?

        "location-id"
      end

      private

      def json_validation
        return if RGeo::GeoJson.encode(RGeo::GeoJSON.decode(form.geojson)) == geojson

        errors.add(:geojson, :invalid)
      end
    end
  end
end
