# frozen_string_literal: true

module Decidim
  module Locations
    class LocationAttributes < GraphQL::Schema::InputObject
      graphql_name "LocationAttributes"
      description "A location attributes"

      argument :id, ID, required: false
      argument :geocode, GraphQL::Types::Boolean, required: false, default_value: false
      argument :address, GraphQL::Types::String, required: false
      argument :latitude, GraphQL::Types::Float, required: true
      argument :longitude, GraphQL::Types::Float, required: true
    end
  end
end
