# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Locations
    describe LocationsHelper do
      let!(:organization) { create(:organization) }
      let!(:dummy1) { create(:dummy_resource, body: "A reasonable body") }
      let!(:dummy2) { create(:dummy_resource, body: "Another reasonable body") }
      let!(:loc1) { create(:location, locatable: dummy1, address: "Speed street", latitude: 50.231241, longitude: 39.394056) }
      let!(:loc2) { create(:location, locatable: dummy2, address: "Brain boulevard", latitude: 14.284756, longitude: 43.182746) }
      let(:helper) do
        Class.new(ActionView::Base) do
          include TranslatableAttributes
          include LocationsHelper
        end.new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, [])
      end

      describe "#format_map_locations - single" do
        subject { helper.format_map_locations(dummy1) }

        it "returns an array of a single model locations" do
          expect(subject).to eq([[dummy1.id, dummy1.title["en"], nil, dummy1.body, loc1.address, loc1.latitude, loc1.longitude]])
        end
      end

      describe "#format_map_locations - multiple" do
        let(:dummies) { Decidim::DummyResources::DummyResource.where(id: [dummy1.id, dummy2.id]) }

        subject { helper.format_map_locations(dummies) }

        it "returns an array of multiple model locations" do
          expect(subject).to include(
            [dummy1.id, dummy1.title["en"], nil, dummy1.body, loc1.address, loc1.latitude, loc1.longitude],
            [dummy2.id, dummy2.title["en"], nil, dummy2.body, loc2.address, loc2.latitude, loc2.longitude]
          )
        end
      end

      describe "#model_has_address?" do
        context "when model has address" do
          subject { model_has_address?(dummy1) }

          it "returns true" do
            expect(subject).to be(true)
          end
        end

        context "when model has no address" do
          let(:dummy3) { create(:dummy_resource) }

          subject { model_has_address?(dummy3) }

          it "returns false" do
            expect(subject).to be(false)
          end
        end
      end
    end
  end
end
