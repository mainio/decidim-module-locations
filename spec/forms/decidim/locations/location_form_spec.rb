# frozen_string_literal: true

require "spec_helper"

describe Decidim::Locations::LocationForm do
  subject { form }

  let(:form) { described_class.from_params(attributes) }

  context "when all details are provided" do
    let(:attributes) do
      {
        address: "Veneentekijäntie 4 A, 00210 Helsinki",
        latitude: 50.149792,
        longitude: 24.887430,
        shape: "Point",
        geojson: "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",
                  \"coordinates\":[50.25354187363282,18.457031250000004]
                  }}"
      }
    end

    it { is_expected.to be_valid }
  end

  context "when all details are blank" do
    let(:attributes) do
      {
        address: "",
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
        latitude: 50.149792,
        longitude: 24.887430,
        shape: "Point",
        geojson: "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",
                  \"coordinates\":[50.25354187363282,18.457031250000004]
                  }}"
      }
    end

    it { is_expected.to be_valid }
  end

  context "when geojson not provided" do
    let(:attributes) do
      {
        address: "Veneentekijäntie 4 A, 00210 Helsinki",
        latitude: 50.149792,
        longitude: 24.887430,
        shape: "Point"
      }
    end

    it { is_expected.to be_valid }

    it "is expected to fill the geojson" do
      expect(subject.geojson).to eq('{"type":"Feature","geometry":{"type":"Point","coordinates":[50.149792,24.88743]}}')
    end
  end

  context "when shape not provided" do
    let(:attributes) do
      {
        address: "Veneentekijäntie 4 A, 00210 Helsinki",
        latitude: 50.149792,
        longitude: 24.887430,
        geojson: "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",
                  \"coordinates\":[50.149792,24.887430]
                  }}"
      }
    end

    it { is_expected.to be_valid }

    it "is expected to fill the shape" do
      expect(subject.shape).to eq("Point")
    end
  end

  context "when geojson is not correct" do
    context "when cannot be parsed to JSON" do
      let(:attributes) do
        {
          address: "Veneentekijäntie 4 A, 00210 Helsinki",
          latitude: 50.149792,
          longitude: 24.887430,
          shape: "Point",
          geojson: "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",
                    \"coordinates\":[example,18.457031250000004]
                    }}"
        }
      end

      it { is_expected.not_to be_valid }
    end

    context "when coordinates don't exist" do
      let(:attributes) do
        {
          address: "Veneentekijäntie 4 A, 00210 Helsinki",
          latitude: 50.149792,
          longitude: 24.887430,
          shape: "Point",
          geojson: "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",
                    \"coordinates\":[210.25354187363282,18.457031250000004]
                    }}"
        }
      end

      it { is_expected.not_to be_valid }
    end
  end
end
