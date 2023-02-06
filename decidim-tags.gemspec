# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "decidim/locations/version"

Gem::Specification.new do |spec|
  spec.name = "decidim-locations"
  spec.version = Decidim::Locations::VERSION
  spec.required_ruby_version = ">= 2.7"
  spec.authors = ["Antti Hukkanen"]
  spec.email = ["antti.hukkanen@mainiotech.fi"]

  spec.summary = "Adds possibility to add locations to any records."
  spec.description = "Developers can define the locations functionality to any existing objects and the users can add locations to different records."
  spec.homepage = "https://github.com/mainio/decidim-module-locations"
  spec.license = "AGPL-3.0"

  spec.files = Dir[
    "{app,config,lib}/**/*",
    "LICENSE-AGPLv3.txt",
    "Rakefile",
    "README.md"
  ]

  spec.require_paths = ["lib"]

  spec.add_dependency "decidim-core", Decidim::Locations::DECIDIM_VERSION

  spec.add_development_dependency "decidim-dev", Decidim::Locations::DECIDIM_VERSION

  spec.metadata["rubygems_mfa_required"] = "true"
end
