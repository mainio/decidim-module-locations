# frozen_string_literal: true

require "rgeo"
require "rgeo/geo_json"

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
      # validate :json_validation, if: ->(form) { form.geojson.present? && !form.deleted }

      def to_param
        return id if id.present?

        "location-id"
      end

      # private

      # def json_validation
      #   case shape
      #   when "Marker"
      #     marker = "{\"type\":\"Point\", \"coordinates\":[#{geojson["lat"], geojson["lng"]}]}"
      #   when "Line"
      #     line = "{\"type\":\"LineString\", \"coordinates\":[#{geojson["lat"], geojson["lng"]}]}"
      #   when "Polygon"
      #     polygon = "{\"type\":\"Polygon\", \"coordinates\":[#{geojson["lat"], geojson["lng"]}]}"
      #   end
      # end
    end
  end
end
