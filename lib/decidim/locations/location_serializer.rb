# frozen_string_literal: true

module Decidim
  module Locations
    # This class serializes a Location so can be exported to CSV, JSON or other
    # formats.
    class LocationSerializer < Decidim::Exporters::Serializer
      # Public: Initializes the serializer with a location.
      def initialize(location)
        @location = location
      end

      # Public: Exports a hash with the serialized data for this location.
      def serialize
        record = Object.const_get(@location.decidim_locations_locatable_type)

        {
          type: "Feature",
          geometry: {
            type: @location.shape,
            coordinates:
              @location.geojson["geometry"]["coordinates"]
          },
          properties:
            if @location.decidim_locations_locatable_type != "Decidim::Forms::Answer"
              {
                id: @location.decidim_locations_locatable_id,
                title: record.where(id: @location.decidim_locations_locatable_id).first.try(:title),
                description: if record.where(id: @location.decidim_locations_locatable_id).first.respond_to?(:description)
                               record.where(id: @location.decidim_locations_locatable_id).first.description
                             elsif record.where(id: @location.decidim_locations_locatable_id).first.respond_to?(:body)
                               record.where(id: @location.decidim_locations_locatable_id).first.body
                             end,
                type: record.name
              }
            elsif @location.decidim_locations_locatable_type == "Decidim::Forms::Answer"
              {
                id:
                  Decidim::Forms::Question
                    .where(id: Decidim::Forms::Answer
                    .where(id: @location.decidim_locations_locatable_id)
                    .first
                    .decidim_question_id)
                    .first
                    .id,
                title:
                  Decidim::Forms::Question
                    .where(id: Decidim::Forms::Answer
                    .where(id: @location.decidim_locations_locatable_id)
                    .first
                    .decidim_question_id)
                    .first
                    .body,
                description:
                  Decidim::Forms::Question
                    .where(id: Decidim::Forms::Answer
                    .where(id: @location.decidim_locations_locatable_id)
                    .first
                    .decidim_question_id)
                    .first
                    .description,
                type: "Decidim::Forms::Question"
              }
            end
        }
      end
    end
  end
end
