# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

Decidim::Webpacker.register_path("#{base_path}/app/packs", prepend: true)

Decidim::Webpacker.register_entrypoints(
  decidim_locations_admin: "#{base_path}/app/packs/entrypoints/decidim_locations_admin.js",
  decidim_locations: "#{base_path}/app/packs/entrypoints/decidim_locations.js",
  decidim_locations_edit_map: "#{base_path}/app/packs/entrypoints/decidim_locations_edit_map.js"
)
Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/locations/locations")
Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/locations/locations", group: :admin)
