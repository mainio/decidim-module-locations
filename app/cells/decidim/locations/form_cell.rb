# frozen_string_literal: true

module Decidim
  module Locations
    # This cell renders the locations input for the given form.
    class FormCell < Decidim::ViewModel
      include Cell::ViewModel::Partial
      include Decidim::TranslatableAttributes

      delegate :snippets, to: :controller

      def show
        unless snippets.any?(:locations)
          snippets.add(:locations, javascript_pack_tag("decidim_locations_admin"))

          # This will display the snippets in the <head> part of the page.
          snippets.add(:head, snippets.for(:locations))
        end

        render
      end

      private

      def existing_locations_for(form)
        return [] unless form
        return [] unless form.object

        form.object.locations
      end

      def field_name(index = "")
        return "locations[#{index}]" if form.blank? || form.object_name.blank?

        "#{form.object_name}[locations][#{index}]"
      end

      def input_id(form)
        @input_id ||= options[:id] || begin
          base = form.object_name.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").delete_suffix("_")
          "#{base}_locations"
        end
      end

      def tabs_id_for_location(location)
        "location_#{location.to_param}"
      end

      def blank_location
        @blank_location ||= Decidim::Locations::LocationForm.new
      end

      def form
        model
      end

      # def label
      #   return false if options[:label] == false

      #   options[:label] || I18n.t("activemodel.attributes.locations.locations")
      # end
    end
  end
end
