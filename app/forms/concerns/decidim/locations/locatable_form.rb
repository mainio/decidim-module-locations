# frozen_string_literal: true

module Decidim
  module Locations
    module LocatableForm
      extend ActiveSupport::Concern

      included do
        attribute :locations, Array[Decidim::Locations::LocationForm]
      end

      private

      def map_locations(model)
        # The model can be a collection proxy if the map_model is called through
        # the parent record's map_model method.
        self.locations =
          if model.is_a?(ActiveRecord::Associations::CollectionProxy)
            model.map { |location| LocationForm.from_model(location) }
          else
            model.locations.map { |location| LocationForm.from_model(location) }
          end
      end
    end
  end
end
