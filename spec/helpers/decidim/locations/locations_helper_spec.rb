# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Locations
    describe LocationsHelper do
      let!(:organization) { create(:organization) }
      let!(:proposal_component) { create(:proposal_component, :with_geocoding_enabled, organization: organization) }
      let!(:dummy1) { create(:dummy_resource, title: { en: "Let's go" }, body: "Running tournament for teenagers") }
      let!(:dummy2) { create(:dummy_resource, title: { en: "Think better" }, body: "Chess tournament for teenagers") }
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

        it "returns an array of a single proposal locations" do
          expect(subject).to eq([[dummy1.id, "Let's go", nil, "Running tournament for teenagers", "Speed street", 50.231241, 39.394056]])
        end
      end

      describe "#format_map_locations - multiple" do
        let(:props) { Decidim::DummyResources::DummyResource.where(id: [prop1.id, prop2.id]) }
        let(:dummies) { Decidim::DummyResources::DummyResource.where(id: [dummy1.id, dummy2.id]) }

        subject { helper.format_map_locations(dummies) }

        it "returns an array of multiple proposal locations" do
          expect(subject).to include([dummy1.id, "Let's go", nil, "Running tournament for teenagers", "Speed street", 50.231241, 39.394056],
                                     [dummy2.id, "Think better", nil, "Chess tournament for teenagers", "Brain boulevard", 14.284756, 43.182746])
        end
      end
    end
  end
end