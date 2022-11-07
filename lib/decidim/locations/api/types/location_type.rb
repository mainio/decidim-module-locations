# frozen_string_literal: true

module Decidim
  module Locations
    class LocationType < GraphQL::Schema::Object
      graphql_name "Location"
      description "A location"

      field :id, GraphQL::Types::ID, null: false
      field :address, GraphQL::Types::String, "The address for this location", null: true
      field :latitude, GraphQL::Types::Float, "The latitude coordinate for this location", null: true
      field :longitude, GraphQL::Types::Float, "The longitude coordinate for this location", null: true
    end
  end
end
