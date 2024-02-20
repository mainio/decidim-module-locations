# frozen_string_literal: true

module Decidim
  module Locations
    module ProposalsTypeExtensions
      extend ActiveSupport::Concern

      included do
        field :geojson, [GraphQL::Types::JSON], "The geojson for all proposal locations under this component", null: true

        def geojson
          component_id = object.id

          proposals = Decidim::Proposals::Proposal.where(decidim_component_id: component_id)

          locations = proposals.map(&:locations).flatten.compact

          locations.map do |location|
            proposal = Decidim::Proposals::Proposal.where(id: location.decidim_locations_locatable_id).first

            {
              type: "Feature",
              geometry: location.geojson["geometry"],
              properties: {
                id: proposal.id,
                title: proposal.title,
                description: proposal.body,
                type: "Decidim::Proposals::Proposal"
              }
            }
          end
        end
      end
    end
  end
end
