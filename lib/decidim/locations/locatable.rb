# frozen_string_literal: true

module Decidim
  module Locations
    # A concern that needs to be included in all records that need locations.
    module Locatable
      extend ActiveSupport::Concern

      included do
        has_many :locations,
                 as: :locatable,
                 foreign_key: :decidim_locations_locatable_id,
                 foreign_type: :decidim_locations_locatable_type,
                 class_name: "Decidim::Locations::Location",
                 dependent: :destroy
      end
    end
  end
end
