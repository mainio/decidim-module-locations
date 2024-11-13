# frozen_string_literal: true

module Decidim
  module Locations
    # This cell renders a map which you can use to determine the location(s) for the form.
    class LocationsCell < Decidim::ViewModel
      include Decidim::IconHelper
      include Decidim::Locations::LocationsHelper
      include Decidim::MapHelper
      include Escaped

      delegate :snippets, to: :controller

      def show
        render
      end

      def existent_locations
        form.object.locations
      end

      def form
        options[:form]
      end

      def coords
        options[:coords]
      end

      def zoom
        return 14 unless options[:zoom]

        options[:zoom]
      end

      def map_configuration
        options[:map_configuration]
      end

      def select_location?
        return false unless options[:select_location]

        true
      end

      def randomize_loc
        charset = ("a".."z").to_a + ("0".."9").to_a
        Array.new(7) { charset.sample }.join
      end

      def random_id
        @random_id ||= begin
          charset = ("a".."z").to_a + ("0".."9").to_a
          Array.new(7) { charset.sample }.join
        end
      end

      def add_snippets
        return if snippets.any?(:locations_map_scripts)

        snippets.add(:locations_map_scripts, javascript_include_tag(sources("decidim_locations_edit_map", :javascript)))
        snippets.add(:foot, snippets.for(:locations_map_scripts))
      end
    end
  end
end
