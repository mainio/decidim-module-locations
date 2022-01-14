# frozen_string_literal: true

module Decidim
  module Locations
    module LocatableForm
      extend ActiveSupport::Concern

      included do
        attribute :locations, Array[Decidim::Locations::LocationForm]
      end

      class_methods do
        attr_reader :locations_record_class

        def validates_locations_for(record_class)
          @locations_record_class = record_class
          validate :validate_locations
        end
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

      def validate_locations
        provided_ids = locations.map { |l| l.id.presence }.compact
        if id.blank?
          return unless locations.any? { |l| l.id.present? }

          errors.add(:locations, I18n.t("decidim.locations.form.unexisting_locations", ids: provided_ids.join(", ")))
          return
        end

        record = self.class.locations_record_class.find_by(id: id)
        return unless record

        unexisting_ids = provided_ids - record.locations.pluck(:id)
        return if unexisting_ids.blank?

        errors.add(:locations, I18n.t("decidim.locations.form.unexisting_locations", ids: unexisting_ids.join(", ")))
      end
    end
  end
end
