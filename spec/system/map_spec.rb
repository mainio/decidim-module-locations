# frozen_string_literal: true

require "spec_helper"

describe "Map", type: :system do
  let!(:organization) { create(:organization) }

  let(:template_class) do
    Class.new(ActionView::Base) do
      include ::Cell::RailsExtensions::ActionView

      delegate :snippets, :current_organization, to: :controller

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
  let(:markers) { [[123, "Title of the record", "Summary of the record", "Body text of the record", "Foobar street 123", 1.123, 2.234]] }
  let(:cell) { template.cell("decidim/locations/map", markers) }
  let(:javascript) { template.javascript_pack_tag("decidim_core", defer: false) }

  let(:html_document) do
    cell_html = cell.to_s
    js = javascript
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
          #{js}
          #{snippets.display(:foot)}
        </body>
        </html>
      HTML
    end
  end

  let(:revgeo) do
    <<~JS
      $(function() {
        // Override jQuery AJAX in order to check the request is
        // sent correctly.
        $.ajax = function(request) {
          let response = {};
          if (request.url === "https://revgeocode.search.hereapi.com/v1/revgeocode") {
            response = {
              items: [
                {
                  address: {
                    street: "Veneentekijäntie",
                    houseNumber: 4,
                    country: "FI"
                  },
                  position: {
                    lat: 11.521,
                    lng: 5.521
                  }
                }
              ]
            };
          }

          // This is a normal suggest call to:
          // https://revgeocode.search.hereapi.com/v1/revgeocode
          var deferred = $.Deferred().resolve(response);
          return deferred.promise();
        };
      });
    JS
  end

  context "when map cell rendered" do
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

  context "when location added" do
    def add_marker
      marker_add = <<~JS
        var map = $(".picker-wrapper [data-decidim-map]").data("map");
        var loc = L.latLng(11.521, 5.521);
        map.fire("click", { latlng: loc });
        map.panTo(loc);
      JS
      sleep 1
      page.execute_script(marker_add)
    end

    def drag_marker
      marker_drag = <<~JS
        var ctrl = $(".picker-wrapper [data-decidim-map]").data("map-controller");
        var marker = ctrl.markers[Object.keys(ctrl.markers)[0]];

        marker.setLatLng(L.latLng(13.2, 11.4))
        marker.fire("dragend");
      JS
      sleep 1
      page.execute_script(marker_drag)
    end

    let(:dummy) { create(:dummy_resource, body: "A reasonable body") }
    let(:dummy_form) { Decidim::DummyResources::DummyResourceForm.from_model(dummy) }
    let(:form) { Decidim::FormBuilder.new("dummy", dummy_form, template, {}) }
    let(:map_configuration) { "multiple" }

    let(:cell) { template.cell("decidim/locations/locations", dummy, form: form, map_configuration: map_configuration, coords: [12, 2], checkbox: false) }

    context "when geocoding" do
      # Console.warn print tool
      # puts page.driver.browser.manage.logs.get(:browser).map(&:message).join("\n")

      before do
        tile_content = File.read(Decidim::Dev.asset("icon.png"))
        final_html = html_document
        geocode_response = {
          type: "FeatureCollection",
          features: [
            {
              geometry: {
                coordinates: [24.886418020451863, 60.152602900000005],
                type: "Point"
              },
              type: "Feature",
              properties: {
                osm_type: "W",
                osm_key: "building",
                country: "Finland",
                countrycode: "FI",
                street: "Veneentekijäntie",
                housenumber: 4,
                type: "house"
              }
            },
            {
              geometry: {
                coordinates: [24.8886319, 60.1523368],
                type: "Point"
              },
              type: "Feature",
              properties: {
                osm_type: "W",
                osm_key: "building",
                country: "Finland",
                countrycode: "FI",
                street: "Veneentekijäntie",
                housenumber: 6,
                type: "house"
              }
            },
            {
              geometry: {
                coordinates: [24.8868987, 60.1521989],
                type: "Point"
              },
              type: "Feature",
              properties: {
                osm_type: "W",
                osm_key: "building",
                country: "Finland",
                countrycode: "FI",
                street: "Veneentekijäntie",
                housenumber: 7,
                type: "house"
              }
            }
          ]
        }

        # Create a temporary route to display the generated HTML in a correct site
        # context.

        Rails.application.routes.draw do
          # Map tiles
          get "/tiles/:z/:x/:y", to: ->(_) { [200, {}, [tile_content]] }

          # Geocode response
          get "/geocode", to: ->(_) { [200, { "Content-Type" => "application/json" }, [geocode_response.to_json]] }

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

      context "when typing locations" do
        it "adds marker" do
          click_link "Type locations"
          expect(page).to have_css(".type-loc-field")
          sleep 1
          find("#dummy_address").set("veneen")
          expect(page).to have_content(
            "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
          )
          find("#autoComplete_result_0").click
          click_button "Add"
          expect(page).to have_css(".leaflet-marker-draggable")
        end
      end

      context "when adding multiple locations" do
        it "adds multiple if configured accordingly" do
          click_link "Type locations"
          expect(page).to have_css(".type-loc-field")
          sleep 1
          find("#dummy_address").set("veneen")
          expect(page).to have_content(
            "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
          )
          find("#autoComplete_result_0").click
          click_button "Add"
          expect(page).to have_css(".leaflet-marker-draggable")
          expect(page).to have_css(".leaflet-marker-draggable", count: 1)
          find("#dummy_address").set("veneen")
          expect(page).to have_content(
            "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
          )
          find("#autoComplete_result_1").click
          click_button "Add"
          expect(page).to have_css(".leaflet-marker-draggable")
          expect(page).not_to have_css(".leaflet-marker-draggable", count: 1)
          expect(page).to have_css(".leaflet-marker-draggable", count: 2, visible: :all)
        end
      end

      context "when adding multiple locations and configuration limits it" do
        let(:map_configuration) { "single" }

        it "adds a single location" do
          click_link "Type locations"
          expect(page).to have_css(".type-loc-field")
          find("#dummy_address").set("veneen")
          expect(page).to have_content(
            "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
          )
          find("#autoComplete_result_0").click
          click_button "Add"
          expect(page).to have_css(".marker-field")
          expect(page).to have_css(".leaflet-marker-draggable", count: 1)
          expect(page).to have_field("dummy_locations__index__address", type: :hidden, with: "Veneentekijäntie 4, Finland")
          find("#dummy_address").set("veneen")
          expect(page).to have_content(
            "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
          )
          find("#autoComplete_result_1").click
          click_button "Add"
          expect(page).to have_field("dummy_locations__index__address", type: :hidden, with: "Veneentekijäntie 6, Finland")
          expect(page).to have_css(".leaflet-marker-draggable", count: 1)
        end
      end

      context "when adding a location and changing its address from the modal" do
        it "changes the address field to the form" do
          click_link "Type locations"
          expect(page).to have_css(".type-loc-field")
          sleep 1
          find("#dummy_address").set("veneen")
          expect(page).to have_content(
            "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
          )
          find("#autoComplete_result_0").click
          click_button "Add"
          expect(page).to have_selector("input[value=\"Veneentekijäntie 4, Finland\"]", visible: :hidden)
          find(".leaflet-marker-draggable").click
          find("input[name=\"address\"]").fill_in with: "Example street"
          click_button "Save"
          expect(page).to have_selector("input[value=\"Example street\"]", visible: :hidden)
        end
      end
    end

    context "when reverse geocoding" do
      before do
        utility = Decidim::Map.autocomplete(organization: organization)
        allow(Decidim::Map).to receive(:autocomplete).with(organization: organization).and_return(utility)
        allow(utility).to receive(:builder_options).and_return(
          api_key: "key1234"
        )

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

      context "when picking locations" do
        it "adds markers" do
          page.execute_script(revgeo)
          add_marker
          expect(page).to have_css(".leaflet-marker-draggable")
          sleep 1
        end
      end

      context "when marker added and clicked" do
        it "opens a modal that shows the marker's address" do
          page.execute_script(revgeo)
          add_marker

          expect(page).to have_css(".location-address", visible: :hidden)
          find(".leaflet-marker-draggable").click
          expect(page).to have_content("Save")
        end
      end

      context "when marker dragged" do
        it "updates marker's coordinates" do
          page.execute_script(revgeo)
          add_marker
          drag_marker
          expect(find(".location-latitude", visible: :hidden).value).to eq("13.2")
          expect(find(".location-longitude", visible: :hidden).value).to eq("11.4")
        end
      end

      context "when marker added and clicked too fast" do
        let(:revgeo) do
          <<~JS
            $(function() {
              // Override jQuery AJAX in order to check the request is
              // sent correctly.
              $.ajax = function(request) {

                const response = {};

                  // This is a normal suggest call to:
                  // https://revgeocode.search.hereapi.com/v1/revgeocode
                  var deferred = $.Deferred((def) => {
                    setTimeout(() => {
                      def.resolve(response)
                    }, 500)
                  });
                  return deferred.promise();
              };
            });
          JS
        end

        it "opens a popup that tells the user the address is being fetched" do
          page.execute_script(revgeo)
          add_marker
          find(".leaflet-marker-draggable").click
          expect(page).to have_content("Fetching address for this marker")
        end
      end

      context "when marker deleted" do
        it "deletes the marker from the map" do
          page.execute_script(revgeo)
          add_marker
          expect(page).to have_css(".leaflet-marker-draggable")
          find(".leaflet-marker-draggable").click
          click_button "Delete marker"
          expect(page).not_to have_css(".leaflet-marker-draggable")
        end
      end

      context "when multiple markers and other one deleted" do
        it "deletes only one" do
          page.execute_script(revgeo)
          add_marker
          add_marker
          expect(page).to have_css(".leaflet-marker-draggable", count: 2, visible: :all)
          all(".leaflet-marker-draggable")[1].click
          click_button "Delete marker"
          expect(page).to have_css(".leaflet-marker-draggable", count: 1, visible: :all)
        end
      end
    end
  end

  context "when rendering more than one cell" do
    let(:dummy) { create(:dummy_resource, body: "A reasonable body") }
    let(:dummy_form) { Decidim::DummyResources::DummyResourceForm.from_model(dummy) }
    let(:form) { Decidim::FormBuilder.new("dummy", dummy_form, template, {}) }
    let(:cell) { template.cell("decidim/locations/locations", dummy, form: form, map_configuration: "single", coords: [12, 2], checkbox: false) }
    let(:cell_two) { template.cell("decidim/locations/locations", dummy, form: form, map_configuration: "multiple", coords: [12, 2], checkbox: false) }

    let(:html_document) do
      cell_html = cell.to_s
      cell_two_html = cell_two.to_s
      js = javascript
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
            #{cell_two_html}
            #{js}
            #{snippets.display(:foot)}
          </body>
          </html>
        HTML
      end
    end

    before do
      utility = Decidim::Map.autocomplete(organization: organization)
      allow(Decidim::Map).to receive(:autocomplete).with(organization: organization).and_return(utility)
      allow(utility).to receive(:builder_options).and_return(
        api_key: "key1234"
      )
      allow(cell).to receive(:random_id).and_return("example")
      allow(cell_two).to receive(:random_id).and_return("exampletwo")

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

    it "renders multiple maps" do
      expect(page).to have_css("[data-decidim-map] .leaflet-map-pane img")
      expect(page).to have_content("Pick locations", count: 2)
      expect(page).to have_content("Type locations", count: 2)
    end

    context "when adding markers" do
      it "adds markers correctly" do
        page.execute_script(revgeo)

        within "#pick_model_locations_mapexample" do
          find("[data-decidim-map]").click
          find("[data-decidim-map]").click(x: 10, y: 10)
        end

        within "#pick_model_locations_mapexampletwo" do
          find("[data-decidim-map]").click
          find("[data-decidim-map]").click(x: 10, y: 10)
        end

        within "#pick_model_locations_mapexample" do
          expect(page).to have_css(".leaflet-marker-draggable", count: 1, visible: :all)
        end

        within "#pick_model_locations_mapexampletwo" do
          expect(page).to have_css(".leaflet-marker-draggable", count: 2, visible: :all)
        end
      end
    end
  end

  context "when cell has 'has location' -checkbox" do
    let(:dummy) { create(:dummy_resource, body: "A reasonable body") }
    let(:dummy_form) { Decidim::DummyResources::DummyResourceForm.from_model(dummy) }
    let(:form) { Decidim::FormBuilder.new("dummy", dummy_form, template, {}) }
    let(:map_configuration) { "multiple" }
    let(:cell) { template.cell("decidim/locations/locations", dummy, form: form, map_configuration: map_configuration, coords: [12, 2], checkbox: true) }

    before do
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
    end

    after do
      expect_no_js_errors

      # Reset the routes back to original
      Rails.application.reload_routes!
    end

    it "checks the box if text is clicked" do
      expect(page).to have_content("Has location")
      find('label[for="dummy_has_location"]').click
      expect(page).to have_css("[data-decidim-map] .leaflet-map-pane img")

      loop do
        break if page.all("[data-decidim-map] .leaflet-map-pane img").all? { |img| img["complete"] == "true" }

        sleep 0.1
      end
    end
  end
end
