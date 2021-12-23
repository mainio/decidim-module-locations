# frozen_string_literal: true

module Decidim
  module Locations
    autoload :LocationsInterface, "decidim/locations/api/interfaces/locations_interface"
    autoload :LocationType, "decidim/locations/api/types/location_type"
    autoload :LocationAttributes, "decidim/locations/api/types/location_attributes"
  end
end
