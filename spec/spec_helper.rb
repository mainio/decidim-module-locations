# frozen_string_literal: true

require "decidim/dev"

ENV["ENGINE_ROOT"] = File.dirname(__dir__)

Decidim::Dev.dummy_app_path =
  File.expand_path(File.join(__dir__, "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"

Decidim::DummyResources::DummyResource.include(Decidim::Locations::Locatable)
Decidim::DummyResources::DummyResourceForm.include(Decidim::Locations::LocatableForm)

RSpec.configure do |config|
  config.before :each, type: /system|cell/ do
    allow(Decidim).to receive(:maps).and_return(
      provider: :test,
      dynamic: { tile_layer: { url: "/tiles/{z}/{x}/{y}.png" } },
      geocoding: { url: "/geocode" },
      autocomplete: { url: "/geocode", address_format: [%w(street housenumber), "city", "country"] }
    )
  end
end
