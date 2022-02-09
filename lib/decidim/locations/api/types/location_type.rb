# frozen_string_literal: true

module Decidim
  module Locations
    LocationType = GraphQL::ObjectType.define do
      name "LocationType"
      description "A location with coordinates and address for results"

      field :id, !types.ID, "The internal ID for this status"
      field :address, types.String, "The address of the location."
      field :latitude, types.Float, "The latitude coordinate of the location."
      field :longitude, types.Float, "The longitude coordinate of the location."
    end

    # TODO: Update to 0.24
    # class LocationType < GraphQL::Schema::Object
    #   graphql_name "Location"
    #   description "A location"

    #   field :id, GraphQL::Types::ID, null: false
    #   field :address, GraphQL::Types::String, "The address for this location", null: true
    #   field :latitude, GraphQL::Types::Float, "The latitude coordinate for this location", null: true
    #   field :longitude, GraphQL::Types::Float, "The longitude coordinate for this location", null: true
    # end
  end
end
