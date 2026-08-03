# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

Decidim::Shakapacker.register_path("#{base_path}/app/packs", prepend: true)

Decidim::Shakapacker.register_entrypoints(
  decidim_locations_admin: "#{base_path}/app/packs/entrypoints/decidim_locations_admin.js",
  decidim_locations: "#{base_path}/app/packs/entrypoints/decidim_locations.js",
  decidim_locations_edit_map: "#{base_path}/app/packs/entrypoints/decidim_locations_edit_map.js"
)
Decidim::Shakapacker.register_stylesheet_import("stylesheets/decidim/locations/locations")
Decidim::Shakapacker.register_stylesheet_import("src/decidim/geoman/leaflet-geoman-2.18.3")
Decidim::Shakapacker.register_stylesheet_import("stylesheets/decidim/locations/locations", group: :admin)
Decidim::Shakapacker.register_stylesheet_import("src/decidim/geoman/leaflet-geoman-2.18.3", group: :admin)
