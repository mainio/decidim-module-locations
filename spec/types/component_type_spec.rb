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

      let!(:location_one) { create(:location, locatable: model, skip_injection: true) }
      let!(:location_two) { create(:location, locatable: model, skip_injection: true) }
      let(:model) { create(:dummy_component) }
      let(:query) { "{ locations { id address longitude latitude } }" }

      describe "locations" do
        it "returns the location fields" do
          addresses = response["locations"].map { |location| location["address"] }
          expect(addresses).to contain_exactly(location_one.address, location_two.address)
        end
      end

      describe "longitudes" do
        it "returns the location fields" do
          addresses = response["locations"].map { |location| location["longitude"] }
          expect(addresses).to contain_exactly(location_one.longitude, location_two.longitude)
        end
      end

      describe "latitudes" do
        it "returns the location fields" do
          addresses = response["locations"].map { |location| location["latitude"] }
          expect(addresses).to contain_exactly(location_one.latitude, location_two.latitude)
        end
      end

      describe "ids" do
        it "returns the location fields" do
          addresses = response["locations"].map { |location| location["id"] }
          expect(addresses).to contain_exactly(location_one.id.to_s, location_two.id.to_s)
        end
      end
    end
  end
end
