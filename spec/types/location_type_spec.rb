# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

module Decidim
  module Locations
    describe LocationType do
      include_context "with a graphql class type"
      let(:dummy) { create(:dummy_resource) }
      let(:model) { create(:location, locatable: dummy) }

      describe "id" do
        let(:query) { "{ id }" }

        it "returns the locations's id" do
          expect(response["id"]).to eq(model.id.to_s)
        end
      end

      describe "address" do
        let(:query) { "{ address }" }

        it "returns the locations's address" do
          expect(response["address"]).to eq(model.address.to_s)
        end
      end

      describe "latitude" do
        let(:query) { "{ latitude }" }

        it "returns the locations's latitude" do
          expect(response["latitude"]).to eq(model.latitude)
        end
      end

      describe "longitude" do
        let(:query) { "{ longitude }" }

        it "returns the locations's longitude" do
          expect(response["longitude"]).to eq(model.longitude)
        end
      end
    end
  end
end
