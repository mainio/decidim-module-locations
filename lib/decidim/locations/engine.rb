# frozen_string_literal: true

module Decidim
  module Locations
    # This is an engine that controls the locations functionality.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Locations

      initializer "decidim_locations.settings_manifest_customization" do
        config.to_prepare do
          # Lib
          Decidim::SettingsManifest::Attribute.include(Decidim::Locations::SettingsManifestExtensions)
        end
      end

      initializer "decidim_locations.add_customizations", after: "decidim.action_controller" do
        config.to_prepare do
          # Helper
          Decidim::Admin::SettingsHelper.include(Decidim::Locations::SettingsHelperExtensions)
        end
      end

      initializer "decidim_locations.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Locations::Engine.root}/app/cells")
      end
    end
  end
end
