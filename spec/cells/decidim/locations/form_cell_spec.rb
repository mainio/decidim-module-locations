# frozen_string_literal: true

require "spec_helper"

describe Decidim::Locations::FormCell, type: :cell do
  subject { my_cell.call }

  let(:my_cell) { cell("decidim/locations/form", form_builder) }
  let!(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:template_class) do
    Class.new(ActionView::Base) do
      include ::Cell::RailsExtensions::ActionView

      delegate :snippets, to: :controller

      def protect_against_forgery?
        false
      end
    end
  end
  let(:dummy) { create(:dummy_resource) }
  let!(:dummy_loc) { create(:location, locatable: dummy, address: "Original address", latitude: 12, longitude: 5) }
  let(:dummy_form) { Decidim::DummyResources::DummyResourceForm.from_model(dummy) }
  let(:controller) do
    double.tap do |ctrl|
      snippets = double
      allow(snippets).to receive(:any?).and_return(true)
      allow(ctrl).to receive(:snippets).and_return(snippets)
    end
  end
  let(:template) { template_class.new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, controller) }
  let(:form_builder) { ActionView::Helpers::FormBuilder.new("dummy", dummy_form, template, {}) }

  context "when cell called" do
    it "renders the view" do
      expect(subject).to have_content("address")
      expect(subject).to have_css("input[name=\"dummy[locations][#{dummy_loc.id}][address]\"]")
      expect(subject).to have_content("latitude")
      expect(subject).to have_css("input[name=\"dummy[locations][#{dummy_loc.id}][latitude]\"]")
      expect(subject).to have_content("longitude")
      expect(subject).to have_css("input[name=\"dummy[locations][#{dummy_loc.id}][longitude]\"]")
      expect(subject).to have_css(".add-location-item")
    end
  end
end
