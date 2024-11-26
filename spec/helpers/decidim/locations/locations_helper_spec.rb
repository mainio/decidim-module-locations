# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Locations
    describe LocationsHelper do
      let!(:organization) { create(:organization) }
      let!(:dummy_one) { create(:dummy_resource, body: "A reasonable body") }
      let!(:dummy_two) { create(:dummy_resource, body: "Another reasonable body") }
      let!(:loc_one) { create(:location, locatable: dummy_one, address: "Speed street", latitude: 50.231241, longitude: 39.394056, shape: "Marker", geojson: { "lat" => 50.231241, "lng" => 39.394056 }) }
      let!(:loc_two) { create(:location, locatable: dummy_two, address: "Brain boulevard", latitude: 14.284756, longitude: 43.182746, shape: "Marker", geojson: { "lat" => 14.284756, "lng" => 43.182746 }) }
      let(:helper) do
        Class.new(ActionView::Base) do
          include TranslatableAttributes
          include LocationsHelper
        end.new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, [])
      end

      describe "#format_map_locations - single" do
        subject { helper.format_map_locations(dummy_one) }

        it "returns an array of a single model locations" do
          expect(subject).to eq([[dummy_one.id, dummy_one.title["en"], nil, dummy_one.body, loc_one.address, loc_one.latitude, loc_one.longitude, "Marker", { "lat" => 50.231241, "lng" => 39.394056 }]])
        end
      end

      describe "#format_map_locations - multiple" do
        let(:dummies) { Decidim::Dev::DummyResource.where(id: [dummy_one.id, dummy_two.id]) }

        subject { helper.format_map_locations(dummies) }

        it "returns an array of multiple model locations" do
          expect(subject).to include(
            [dummy_one.id, dummy_one.title["en"], nil, dummy_one.body, loc_one.address, loc_one.latitude, loc_one.longitude, "Marker", { "lat" => 50.231241, "lng" => 39.394056 }],
            [dummy_two.id, dummy_two.title["en"], nil, dummy_two.body, loc_two.address, loc_two.latitude, loc_two.longitude, "Marker", { "lat" => 14.284756, "lng" => 43.182746 }]
          )
        end
      end

      describe "#model_has_address?" do
        context "when model has address" do
          subject { model_has_address?(dummy_one) }

          it "returns true" do
            expect(subject).to be(true)
          end
        end

        context "when model has no address" do
          let(:dummy_three) { create(:dummy_resource) }

          subject { model_has_address?(dummy_three) }

          it "returns false" do
            expect(subject).to be(false)
          end
        end
      end
    end
  end
end
