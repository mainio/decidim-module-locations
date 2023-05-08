# frozen_string_literal: true

require "spec_helper"

describe "Map", type: :system do
  let!(:organization) { create(:organization) }

  let(:template_class) do
    Class.new(ActionView::Base) do
      include ::Cell::RailsExtensions::ActionView

      delegate :snippets, to: :controller

      def protect_against_forgery?
        false
      end
    end
  end
  let(:controller) do
    Decidim::ApplicationController.new.tap do |ctrl|
      request = double.tap do |r|
        allow(r).to receive(:env).and_return(
          "decidim.current_organization" => organization
        )
        allow(r).to receive(:send_early_hints)
      end

      allow(ctrl).to receive(:request).and_return(request)
    end
  end
  let(:template) { template_class.new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, controller) }
  let(:dummy) { create(:dummy_resource, body: "Body text of the record") }
  let(:location) { create(:location, locatable: dummy) }
  let(:dummy_form) { Decidim::DummyResources::DummyResourceForm.from_model(dummy) }
  let(:form) { Decidim::FormBuilder.new("dummy", dummy_form, template, {}) }

  let(:html_document) do
    cell_html = template.cell("decidim/locations/map", dummy, form).to_s
    template.instance_eval do
      <<~HTML.strip
        <!doctype html>
        <html lang="en">
        <head>
          <title>Map Test</title>
          #{stylesheet_pack_tag "decidim_core", media: "all"}
          #{snippets.display(:head)}
        </head>
        <body>
          <header>
            <a href="#content">Skip to main content</a>
          </header>
          #{cell_html}
          #{javascript_pack_tag "decidim_core", defer: false}
          #{snippets.display(:foot)}
        </body>
        </html>
      HTML
    end
  end

  before do
    # Create a temporary route to display the generated HTML in a correct site
    # context.
    tile_content = File.read(Decidim::Dev.asset("icon.png"))
    final_html = html_document
    Rails.application.routes.draw do
      # Map tiles
      get "/tiles/:z/:x/:y", to: ->(_) { [200, {}, [tile_content]] }

      # The actual editor testing route for these specs
      get "test_map", to: ->(_) { [200, {}, [final_html]] }
    end

    # Login needed for uploading the images
    switch_to_host(organization.host)

    visit "/test_map"

    # Wait for the map to be rendered
    expect(page).to have_css("[data-decidim-map] .leaflet-map-pane img")

    # Wait for all map tile images to be loaded
    loop do
      break if page.all("[data-decidim-map] .leaflet-map-pane img").all? { |img| img["complete"] == "true" }

      sleep 0.1
    end
  end

  after do
    expect_no_js_errors

    # Reset the routes back to original
    Rails.application.reload_routes!
  end

  context "when cell called" do
    it "renders the map" do
      expect(page).to have_css("[data-decidim-map]")
    end
  end

  context "when cell called with 1 location" do
    it "renders the map with 1 marker" do
      expect(page).to have_css(".leaflet-marker-icon")
    end
  end

  context "when marker popup clicked" do
    it "shows the marker's popup" do
      page.find(".leaflet-marker-icon").click
      expect(page).to have_content("Title of the record")
      expect(page).to have_content("Foobar street 123")
    end
  end

  context "when cell called with 3 locations" do
    let(:markers) do
      [
        [111, "Title of the first record", "Sum of the first", "Body of the first", "Foobar street 123", 1.123, 2.234],
        [222, "Title of the second record", "Sum of the second", "Body of the second", "Test street", 1.126, 2.237],
        [333, "Title of the third record", "Sum of the third", "Body of the third", "Temporal street", 1.129, 2.240]
      ]
    end

    it "renders the map with 3 markers" do
      expect(page).to have_css(".leaflet-marker-icon", count: 3)
      expect(page).to have_selector('div[title="Title of the first record"]')
      expect(page).to have_selector('div[title="Title of the second record"]')
      expect(page).to have_selector('div[title="Title of the third record"]')
    end

    context "when a certain marker is clicked" do
      it "opens the correct modal" do
        page.find('div[title="Title of the third record"]').click
        expect(page).to have_content("Title of the third record")
      end
    end
  end
end
