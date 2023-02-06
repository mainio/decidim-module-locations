# frozen_string_literal: true

module Decidim
  module Locations
    # A location record that can be attached to any records.
    class Location < Locations::ApplicationRecord
      belongs_to(
        :locatable,
        foreign_key: :decidim_locations_locatable_id,
        foreign_type: :decidim_locations_locatable_type,
        polymorphic: true
      )
    end
  end
end
