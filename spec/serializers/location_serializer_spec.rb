# frozen_string_literal: true

require "spec_helper"

module Decidim::Locations
  describe LocationSerializer do
    subject { described_class.new(location) }

    let(:location) { create(:location, decidim_locations_locatable_id: record.id, decidim_locations_locatable_type: record.class.name) }
    let(:serialized) { subject.serialize }

    describe "#serialize" do
      context "when proposal" do
        let(:record) { create(:proposal) }

        it "includes the location shape" do
          expect(serialized[:geometry][:type]).to eq(location.shape)
        end

        it "includes the location coordinates" do
          expect(serialized[:geometry][:coordinates]).to eq(location.geojson["geometry"]["coordinates"])
        end

        it "includes the proposal id" do
          expect(serialized[:properties][:id]).to eq(record.id)
        end

        it "includes the proposal title" do
          expect(serialized[:properties][:title]).to eq(record.title)
        end

        it "includes the proposal description" do
          expect(serialized[:properties][:description][:en]).to eq(record.body[:en])
        end

        it "includes the proposal type" do
          expect(serialized[:properties][:type]).to eq(record.class.name)
        end
      end

      context "when meeting" do
        let(:record) { create(:meeting) }

        it "includes the location shape" do
          expect(serialized[:geometry][:type]).to eq(location.shape)
        end

        it "includes the location coordinates" do
          expect(serialized[:geometry][:coordinates]).to eq(location.geojson["geometry"]["coordinates"])
        end

        it "includes the meeting id" do
          expect(serialized[:properties][:id]).to eq(record.id)
        end

        it "includes the meeting title" do
          expect(serialized[:properties][:title]).to eq(record.title)
        end

        it "includes the meeting description" do
          expect(serialized[:properties][:description][:en]).to eq(record.description[:en])
        end

        it "includes the meeting type" do
          expect(serialized[:properties][:type]).to eq(record.class.name)
        end
      end

      context "when answer" do
        let(:record) { create(:answer) }

        it "includes the location shape" do
          expect(serialized[:geometry][:type]).to eq(location.shape)
        end

        it "includes the location coordinates" do
          expect(serialized[:geometry][:coordinates]).to eq(location.geojson["geometry"]["coordinates"])
        end

        it "includes the answer id" do
          expect(serialized[:properties][:id]).to eq(record.id)
        end

        it "includes the answer title" do
          expect(serialized[:properties][:title]).to eq(Decidim::Forms::Question.first.body)
        end

        it "includes the answer description" do
          expect(serialized[:properties][:description][:en]).to eq(record.body["en"])
        end

        it "includes the question type" do
          expect(serialized[:properties][:type]).to eq("Decidim::Forms::Question")
        end
      end
    end
  end
end
