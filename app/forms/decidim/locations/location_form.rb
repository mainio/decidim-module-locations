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

      def initialize(attributes = {})
        super(attributes)

        set_default_attributes unless attributes[:id]
      end

      def to_param
        return id if id.present?

        "location-id"
      end

      private

      def set_default_attributes
        self.shape ||= "Point"
        self.geojson ||= default_geojson
      end

      def default_geojson
        "{\"type\":\"Feature\",\"geometry\":{\"type\":\"#{shape}\",\"coordinates\":[#{latitude},#{longitude}]}}"
      end

      def json_validation
        return if geojson.blank?

        # check if GeoJSON is valid
        begin
          geo_factory = RGeo::Geographic.spherical_factory
          RGeo::GeoJSON.decode(geojson, geo_factory:)

          coord_validation
        rescue JSON::ParserError
          errors.add(:geojson, "Invalid GeoJSON")
        end
      end

      def coord_validation
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
