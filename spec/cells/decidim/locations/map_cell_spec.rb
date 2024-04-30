# frozen_string_literal: true

require "spec_helper"

describe Decidim::Locations::MapCell, type: :cell do
  subject { my_cell.call }

  let(:my_cell) { cell("decidim/locations/map", dummy) }
  let!(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:template_class) do
    Class.new(ActionView::Base) do
      include ::Cell::RailsExtensions::ActionView

      delegate :snippets, to: :controller
    end
  end
  let(:dummy) { create(:dummy_resource, body: "A reasonable body") }
  let!(:dummy_loc) { create(:location, locatable: dummy, address: "Original address", latitude: 12, longitude: 5) }
  let(:controller) do
    double.tap do |ctrl|
      snippets = double
      allow(snippets).to receive(:any?).and_return(true)
      allow(ctrl).to receive(:snippets).and_return(snippets)
    end
  end
  let(:template) { template_class.new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, controller) }

  context "when cell called" do
    it "renders the view" do
      expect(subject).to have_content(
        <<~TXT.squish
          The following element is a map which presents the items on this page as map points.
          The element can be used with a screen reader but it may be hard to understand.
      TXT
      )
      expect(subject).to have_css(".map__help")
      expect(subject).to have_css("[id$='_bottom']")
    end
  end
end
