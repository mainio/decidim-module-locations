# frozen_string_literal: true

require "spec_helper"

describe Decidim::Locations::LocationForm do
  subject { form }

  let(:form) { described_class.from_params(attributes) }

  context "when all details are provided" do
    let(:attributes) do
      {
        address: "Veneentekijäntie 4 A, 00210 Helsinki",
        latitude: 60.149792,
        longitude: 24.887430,
        shape: "Marker",
        geojson: "{ \"lat\":60.149792,\"lng\":24.887430 }"
      }
    end

    it { is_expected.to be_valid }
  end

  context "when all details are blank" do
    let(:attributes) do
      {
        address: "Veneentekijäntie 4 A, 00210 Helsinki",
        shape: "",
        geojson: ""
      }
    end

    it { is_expected.not_to be_valid }

    context "with deleted set to true" do
      let(:attributes) { { deleted: true, address: "" } }

      it { is_expected.to be_valid }
    end
  end

  context "when address is blank but latitude, longitude, shape and geojson are provided" do
    let(:attributes) do
      {
        address: "",
        latitude: 60.149792,
        longitude: 24.887430,
        shape: "Marker",
        geojson: "{ \"lat\":60.149792,\"lng\":24.887430 }"
      }
    end

    it { is_expected.to be_valid }
  end

  context "when geojson not provided" do
    let(:attributes) do
      {
        address: "",
        latitude: 60.149792,
        longitude: 24.887430,
        shape: "Marker",
        geojson: ""
      }
    end

    it { is_expected.not_to be_valid }
  end

  context "when geojson is not correct" do
    context "when cannot be parsed to JSON" do
      let(:attributes) do
        {
          address: "Veneentekijäntie 4 A, 00210 Helsinki",
          latitude: 60.149792,
          longitude: 24.887430,
          shape: "Marker",
          geojson: "{ \"lat\":Example,\"lng\":24.887430 }"
        }
      end

      it { is_expected.not_to be_valid }
    end

    context "when coordinates don't exist" do
      let(:attributes) do
        {
          address: "Veneentekijäntie 4 A, 00210 Helsinki",
          latitude: 90.149792,
          longitude: 24.887430,
          shape: "Marker",
          geojson: "{ \"lat\":90.149792,\"lng\":24.887430 }"
        }
      end

      it { is_expected.not_to be_valid }
    end
  end
end
