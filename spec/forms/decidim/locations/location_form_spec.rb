# frozen_string_literal: true

require "spec_helper"

describe Decidim::Locations::LocationForm do
  subject { form }

  let(:form) { described_class.from_params(attributes) }

  context "when all details are provided" do
    let(:attributes) { { address: "Veneentekijäntie 4 A, 00210 Helsinki", latitude: 60.149792, longitude: 24.887430 } }

    it { is_expected.to be_valid }
  end

  context "when all details are blank" do
    let(:attributes) { { address: "" } }

    it { is_expected.not_to be_valid }

    context "with deleted set to true" do
      let(:attributes) { { deleted: true, address: "" } }

      it { is_expected.to be_valid }
    end
  end

  context "when address is blank but latitude and longitude are provided" do
    let(:attributes) { { address: "", latitude: 60.149792, longitude: 24.887430 } }

    it { is_expected.to be_valid }
  end

  context "when address is blank but only latitude is provided" do
    let(:attributes) { { address: "", latitude: 60.149792 } }

    it { is_expected.not_to be_valid }
  end

  context "when address is blank but only longitude is provided" do
    let(:attributes) { { address: "", longitude: 60.149792 } }

    it { is_expected.not_to be_valid }
  end
end
