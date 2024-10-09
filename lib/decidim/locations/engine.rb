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

          # Lib
          Decidim::Proposals::ProposalsType.include(Decidim::Locations::ProposalsTypeExtensions) if Decidim.module_installed?(:proposals)
          Decidim::Meetings::MeetingsType.include(Decidim::Locations::MeetingsTypeExtensions) if Decidim.module_installed?(:meetings)
          Decidim::Accountability::AccountabilityType.include(Decidim::Locations::AccountabilityTypeExtensions) if Decidim.module_installed?(:accountability)
          Decidim::Surveys::SurveysType.include(Decidim::Locations::SurveysTypeExtensions) if Decidim.module_installed?(:surveys)
        end
      end

      initializer "decidim_locations.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Locations::Engine.root}/app/cells")
      end

      initializer "decidim_locations.register_icons" do
        Decidim.icons.register(name: "more-line", icon: "more-line", category: "system", description: "", engine: :conferences)
      end
    end
  end
end
