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
      validate :json_validation, if: ->(form) { !form.deleted }

      def to_param
        return id if id.present?

        "location-id"
      end

      private

      def json_validation
        if geojson.blank?
          geojson = {
            type: "Feature",
            geometry: {
              type: shape,
              coordinates:
                [latitude, longitude]
            }
          }

          return
        end

        # check if GeoJSON is valid
        begin
          geo_factory = RGeo::Geographic.spherical_factory

          RGeo::GeoJSON.decode(geojson, geo_factory: geo_factory)
        rescue JSON::ParserError
          errors.add(:geojson, "Invalid GeoJSON")
          return
        end

        # check that coordinates are valid
        geo_parse = JSON.parse(geojson)["geometry"]["coordinates"]

        case shape
        when "Point"
          valid_coord?(geo_parse)
        when "LineString"
          geo_parse.each do |coords|
            valid_coord?(coords)
          end
        when "Polygon"
          geo_parse.each do |array|
            array.each do |coords|
              valid_coord?(coords)
            end
          end
        end
      end

      def valid_coord?(coords)
        errors.add(:geojson, "Invalid coordinates") unless coords[0].between?(-90, 90) && coords[1].between?(-180, 180)
      end
    end
  end
end
