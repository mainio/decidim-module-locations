# frozen_string_literal: true

module Decidim
  module Locations
    module LocationsInterface
      include GraphQL::Schema::Interface

      graphql_name "LocationsInterface"
      description "This interface is implemented by any object that can have locations."

      field :locations, [Decidim::Locations::LocationType], null: true do
        description "The locations for this record"
      end
    end
  end
end
