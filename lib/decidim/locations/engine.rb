# frozen_string_literal: true

module Decidim
  module Locations
    # This is an engine that controls the locations functionality.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Locations

      initializer "decidim_locations.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Locations::Engine.root}/app/cells")
      end
    end
  end
end
