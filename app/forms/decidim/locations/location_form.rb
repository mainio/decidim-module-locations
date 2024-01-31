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
        geo_parse = JSON.parse(geojson)
        case shape
        when "Marker"
          valid_marker?(geo_parse)
        when "Line"
          valid_line?(geo_parse)
        when "Polygon"
          valid_polygon?(geo_parse)
        end
      rescue JSON::ParserError
        errors.add(:geojson, "Invalid value")
      end

      def valid_marker?(geo_parse)
        valid_coord?(geo_parse)
      end

      def valid_line?(geo_parse)
        geo_parse.map do |coord|
          valid_coord?(coord)
        end
      end

      def valid_polygon?(geo_parse)
        geo_parse.each do |coords|
          coords.each do |coord|
            valid_coord?(coord)
          end
        end
      end

      def valid_coord?(geo_parse)
        errors.add(:geojson, "Invalid coordinates") unless geo_parse["lat"].between?(-90, 90) && geo_parse["lng"].between?(-180, 180)
      end
    end
  end
end
