# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

module Decidim
  module Core
    # We are really testing: lib/decidim/favorites/api/favorites_interface.rb
    describe ComponentType do
      Decidim::Component.include Decidim::Locations::Locatable
      Decidim::Core::ComponentType.implements Decidim::Locations::LocationsInterface
      include_context "with a graphql class type"

      let!(:location1) { create(:location, locatable: model, skip_injection: true) }
      let!(:location2) { create(:location, locatable: model, skip_injection: true) }
      let(:model) { create(:dummy_component) }
      let(:query) { "{ locations { id address longitude latitude } }" }

      describe "locations" do
        it "returns the location fields" do
          addresses = response["locations"].map { |location| location["address"] }
          expect(addresses).to match_array([location1.address, location2.address])
        end
      end

      describe "longitudes" do
        it "returns the location fields" do
          addresses = response["locations"].map { |location| location["longitude"] }
          expect(addresses).to match_array([location1.longitude, location2.longitude])
        end
      end

      describe "latitudes" do
        it "returns the location fields" do
          addresses = response["locations"].map { |location| location["latitude"] }
          expect(addresses).to match_array([location1.latitude, location2.latitude])
        end
      end

      describe "ids" do
        it "returns the location fields" do
          addresses = response["locations"].map { |location| location["id"] }
          expect(addresses).to match_array([location1.id.to_s, location2.id.to_s])
        end
      end
    end
  end
end
