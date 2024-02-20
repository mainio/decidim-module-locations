# frozen_string_literal: true

module Decidim
  module Locations
    module AccountabilityTypeExtensions
      extend ActiveSupport::Concern

      included do
        field :geojson, [GraphQL::Types::JSON], "The geojson for all proposal locations under this component", null: true

        def geojson
          component_id = object.id

          results = Decidim::Accountability::Result.where(decidim_component_id: component_id)

          locations = results.map(&:locations).flatten.compact

          locations.map do |location|
            result = Decidim::Accountability::Result.where(id: location.decidim_locations_locatable_id).first

            {
              type: "Feature",
              geometry: location.geojson["geometry"],
              properties: {
                id: result.id,
                title: result.title,
                description: result.description,
                type: "Decidim::Accountability::Result"
              }
            }
          end
        end
      end
    end
  end
end
