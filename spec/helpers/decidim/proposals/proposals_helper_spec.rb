# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe ProposalsHelper do
      let!(:organization) { create(:organization) }
      let!(:proposal_component) { create(:proposal_component, :with_geocoding_enabled, organization: organization) }
      let!(:prop1) { create(:proposal, title: "Let's go", body: "Running tournament for teenagers", component: proposal_component) }
      let!(:prop2) { create(:proposal, title: "Think better", body: "Chess tournament for teenagers", component: proposal_component) }
      let!(:loc1) { create(:location, locatable: prop1, address: "Speed street", latitude: 50.231241, longitude: 39.394056) }
      let!(:loc2) { create(:location, locatable: prop2, address: "Brain boulevard", latitude: 14.284756, longitude: 43.182746) }
      let(:helper) do
        Class.new(ActionView::Base) do
          include TranslatableAttributes
          include LocationsHelper
        end.new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, [])
      end

      describe "#format_map_locations - single" do
        subject { helper.parse_map_locations(prop1) }

        it "returns an array of a single proposal locations" do
          expect(subject).to eq([[prop1.id, "Let's go", nil, "Running tournament for teenagers", "Speed street", 50.231241, 39.394056]])
        end
      end

      describe "#format_map_locations - multiple" do
        let(:props) { Proposal.where(id: [prop1.id, prop2.id]) }

        subject { helper.parse_map_locations(props) }

        it "returns an array of multiple proposal locations" do
          expect(subject).to include([prop1.id, "Let's go", nil, "Running tournament for teenagers", "Speed street", 50.231241, 39.394056],
                                     [prop2.id, "Think better", nil, "Chess tournament for teenagers", "Brain boulevard", 14.284756, 43.182746])
        end
      end
    end
  end
end
