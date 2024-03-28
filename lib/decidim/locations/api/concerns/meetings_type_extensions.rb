# frozen_string_literal: true

module Decidim
  module Locations
    module MeetingsTypeExtensions
      extend ActiveSupport::Concern

      included do
        field :geojson, [GraphQL::Types::JSON], "The geojson for all proposal locations under this component", null: true

        def geojson
          component_id = object.id

          meetings = Decidim::Meetings::Meeting.where(decidim_component_id: component_id)

          locations = meetings.map(&:locations).flatten.compact

          locations.map do |location|
            meeting = Decidim::Meetings::Meeting.where(id: location.decidim_locations_locatable_id).first

            {
              type: "Feature",
              geometry: location.geojson["geometry"],
              properties: {
                id: meeting.id,
                title: meeting.title,
                description: meeting.description,
                type: "Decidim::Meetings::Meeting"
              }
            }
          end
        end
      end
    end
  end
end
