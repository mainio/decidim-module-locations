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

      def form
        options[:form]
      end

      def current_organization
        options[:current_organization]
      end

      def classname
        model.class.name.split("::").last.downcase
      end

      def revealselector
        escape!({ revealSelector: "#model_locations_reveal" }.to_json)
      end
    end
  end
end
