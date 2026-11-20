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

  context "when the shape is a polygon" do
    let(:base_attributes) do
      {
        address: "Dummy address",
        latitude: 1.0,
        longitude: 1.0,
        shape: "Polygon"
      }
    end
    let(:attributes) { base_attributes.merge(geojson: polygon_geojson(ring)) }

    def polygon_geojson(ring)
      { type: "Feature", geometry: { type: "Polygon", coordinates: [ring] } }.to_json
    end

    context "when the ring is closed and within range" do
      let(:ring) { [[60.2472, 25.1093], [60.2438, 25.1144], [60.2456, 25.1034], [60.2472, 25.1093]] }

      it { is_expected.to be_valid }
    end

    context "when the longitudes are beyond 90" do
      let(:ring) { [[-65.8268, 104.7656], [-59.3904, -153.9844], [-89.4652, 152.5781], [-65.8268, 104.7656]] }

      it "is valid and does not raise" do
        expect { subject.valid? }.not_to raise_error
        expect(subject).to be_valid
      end
    end

    context "when the ring is open and the longitudes are beyond 90" do
      let(:ring) { [[-65.8268, 104.7656], [-59.3904, -153.9844], [-89.4652, 152.5781]] }

      it "is valid and does not raise" do
        expect { subject.valid? }.not_to raise_error
        expect(subject).to be_valid
      end
    end

    context "when the ring is open and within the range" do
      let(:ring) { [[60.2472, 25.1093], [60.2438, 25.1144], [60.2456, 25.1034]] }

      it "is valid since decoder closes ring" do
        expect(subject).to be_valid
      end
    end

    context "when a longitude is beyond 180" do
      let(:ring) { [[40.0627, -196.1719], [-73.1379, -284.7656], [-60.0990, 92.1094], [40.0627, -196.1719]] }

      it "is invalid because of the coordinate range" do
        expect(subject).not_to be_valid
        expect(subject.errors[:geojson]).to include("Invalid coordinates")
      end
    end

    context "when a latitude is beyond 90" do
      let(:ring) { [[95.0, 25.0], [60.0, 26.0], [61.0, 24.0], [95.0, 25.0]] }

      it "is invalid because of the coordinate range" do
        expect(subject).not_to be_valid
        expect(subject.errors[:geojson]).to include("Invalid coordinates")
      end
    end

    context "when the geometry cannot be built" do
      let(:ring) { [[60.2472, 25.1093], [60.2438, 25.1144], [60.2456, 25.1034], [60.2472, 25.1093]] }

      before do
        allow(RGeo::GeoJSON).to receive(:decode).and_raise(RGeo::Error::InvalidGeometry, "Invalid")
      end

      it "adds an error instead of raising" do
        expect { subject.valid? }.not_to raise_error
        expect(subject).not_to be_valid
        expect(subject.errors[:geojson]).to include("Invalid GeoJSON")
      end
    end

    context "when the shape is a line string with longitudes beyond 90" do
      let(:attributes) do
        {
          address: "Dummy address",
          latitude: 1.0,
          longitude: 1.0,
          shape: "LineString",
          geojson: '{"type":"Feature","geometry":{"type":"LineString","coordinates":[[-15.05, -63.98],[-82.26,159.76]]}}'
        }
      end

      it { is_expected.to be_valid }
    end
  end
end
