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
  let(:marker) do
    [[
      123, "Title of the marker", "Summary of the record", "Body text of the record", "Foobar street 123",
      60.25013831397032, 25.11058330535889, "Marker", { "lat" => 60.25013831397032, "lng" => 25.11058330535889 }
    ]]
  end

  let(:line) do
    [[
      123, "Title of the line", "Summary of the record", "Body text of the record", "Foobar street 123",
      60.241787524015265, 25.11521816253662, "Line", '[{ "lat": 60.24240524264389, "lng": 25.10809421539307 },
      { "lat": 60.24116980538663, "lng": 25.122342109680176 }]'
    ]]
  end

  let(:polygon) do
    [[
      123, "Title of the polygon", "Summary of the record", "Body text of the record", "Foobar street 123",
      60.2455574969813, 25.109066963195804, "Polygon", '[[{ "lat": 60.24721874334426, "lng": 25.109295845031742 },
      { "lat": 60.24381102836454, "lng": 25.114445686340336 },
      { "lat": 60.2456427192351, "lng": 25.103459358215336 }]]'
    ]]
  end

  let(:all_shapes) do
    [
      [
        123, "Title of the marker", "Summary of the record", "Body text of the record", "Foobar street 123",
        60.25013831397032, 25.11058330535889, "Marker", { "lat" => 60.25013831397032, "lng" => 25.11058330535889 }
      ],
      [
        123, "Title of the line", "Summary of the record", "Body text of the record", "Foobar street 123",
        60.241787524015265, 25.11521816253662, "Line", '[{ "lat": 60.24240524264389, "lng": 25.10809421539307 },
        { "lat": 60.24116980538663, "lng": 25.122342109680176 }]'
      ],
      [
        123, "Title of the polygon", "Summary of the record", "Body text of the record", "Foobar street 123",
        60.2455574969813, 25.109066963195804, "Polygon", '[[{ "lat": 60.24721874334426, "lng": 25.109295845031742 },
        { "lat": 60.24381102836454, "lng": 25.114445686340336 },
        { "lat": 60.2456427192351, "lng": 25.103459358215336 }]]'
      ]
    ]
  end

  let(:cell) { template.cell("decidim/locations/map", shapes) }
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

  let(:geocode_response) { {} }
  let(:before_render) { nil }

  let(:use_revgeo) { false }
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

  before do
    if use_revgeo
      # Autocomplete utility override
      utility = Decidim::Map.autocomplete(organization: organization)
      allow(Decidim::Map).to receive(:autocomplete).with(organization: organization).and_return(utility)
      allow(utility).to receive(:builder_options).and_return(
        api_key: "key1234"
      )
    end

    before_render&.call

    # Create a temporary route to display the generated HTML in a correct site
    # context.
    tile_content = File.read(Decidim::Dev.asset("icon.png"))
    final_html = html_document
    gcresponse = geocode_response.to_json

    Rails.application.routes.draw do
      # Map tiles
      get "tiles/:z/:x/:y", to: ->(_) { [200, {}, [tile_content]] }

      # The actual editor testing route for these specs
      get "test_map", to: ->(_) { [200, {}, [final_html]] }

      # Geocode response
      get "geocode", to: ->(_) { [200, { "Content-Type" => "application/json" }, [gcresponse]] }
    end

    switch_to_host(organization.host)
  end

  after do
    expect_no_js_errors

    # Reset the routes back to original
    Rails.application.reload_routes!
  end

  context "when map cell rendered" do
    before do
      visit "/test_map"

      # Wait for the map to be rendered
      expect(page).to have_css("[data-decidim-map] .leaflet-map-pane img")

      # Wait for all map tile images to be loaded
      loop do
        break if page.all("[data-decidim-map] .leaflet-map-pane img").all? { |img| img["complete"] == "true" }

        sleep 0.1
      end
    end

    context "when cell called" do
      let(:shapes) { marker }

      it "renders the map" do
        expect(page).to have_css("[data-decidim-map]")
      end
    end

    context "when cell called with 1 location" do
      context "when marker" do
        let(:shapes) { marker }

        it "renders the map with 1 marker" do
          expect(page).to have_css(".leaflet-marker-icon")
        end
      end

      context "when line" do
        let(:shapes) { line }

        it "renders the map with 1 line" do
          expect(page).to have_css("path.leaflet-interactive")
        end
      end

      context "when polygon" do
        let(:shapes) { polygon }

        it "renders the map with 1 polygon" do
          expect(page).to have_css("path.leaflet-interactive")
        end
      end
    end

    context "when popup clicked" do
      context "when marker" do
        let(:shapes) { marker }

        it "shows the marker's popup" do
          page.find(".leaflet-marker-icon").click
          expect(page).to have_content("Title of the marker")
          expect(page).to have_content("Foobar street 123")
        end
      end

      context "when line" do
        let(:shapes) { line }

        it "shows the line's popup" do
          page.find("path.leaflet-interactive").click
          expect(page).to have_content("Title of the line")
          expect(page).to have_content("Foobar street 123")
        end
      end

      context "when polygon" do
        let(:shapes) { polygon }

        it "shows the polygon's popup" do
          page.find("path.leaflet-interactive").click
          expect(page).to have_content("Title of the polygon")
          expect(page).to have_content("Foobar street 123")
        end
      end
    end

    context "when cell called with 3 locations" do
      let(:shapes) { all_shapes }

      it "renders the map with 3 shapes" do
        expect(page).to have_css(".leaflet-marker-icon", count: 1)
        expect(page).to have_selector('img[title="Title of the marker"]')
        expect(page).to have_css("path.leaflet-interactive", count: 2)
      end

      context "when a certain marker is clicked" do
        it "opens the correct modal" do
          # Since the DOM "path" -elements for the lines and polygons themselves
          # don't have any specific attributes to be tied to a certain location
          # we use the predictivity of the test environment to our advantage because
          # the order is going to be the same everytime
          page.find("path.leaflet-interactive", match: :first).click
          expect(page).to have_content("Title of the line")
        end
      end
    end
  end

  context "when location added" do
    def add_marker(latitude: 11.521, longitude: 5.521)
      find('div[title="Draw Marker"] a').click
      marker_add = <<~JS
        var map = $(".picker-wrapper [data-decidim-map]").data("map");
        var loc = L.latLng(#{latitude}, #{longitude});
        map.fire("click", { latlng: loc });
        map.panTo(loc);
      JS
      sleep 1
      page.execute_script(marker_add)
      find("div.leaflet-pm-actions-container a.leaflet-pm-action.action-cancel").click
      sleep 1
    end

    def add_line(latitude: [60.24240524264389, 60.24116980538663], longitude: [25.10809421539307, 25.122342109680176])
      find('div[title="Draw Polyline"] a').click
      line_add = <<~JS
        var map = $(".picker-wrapper [data-decidim-map]").data("map");
        var first = L.latLng(#{latitude}[0], #{longitude}[0]);
        var second = L.latLng(#{latitude}[1], #{longitude}[1]);
        map.fire("click", { latlng: first });
        map.fire("click", { latlng: second });
      JS
      sleep 1
      page.execute_script(line_add)
      find("div.leaflet-pm-actions-container a.leaflet-pm-action.action-finish").click
      sleep 1
    end

    def add_polygon(latitude: [85.05109772344713, 85.05106347807192, 85.05106162696384], longitude: [24.741251170635227, 24.7408863902092, 24.741551578044895])
      find('div[title="Draw Polygons"] a').click
      polygon_add = <<~JS
        var map = $(".picker-wrapper [data-decidim-map]").data("map");
        var first = L.latLng(#{latitude}[0], #{longitude}[0]);
        var second = L.latLng(#{latitude}[1], #{longitude}[1]);
        var third = L.latLng(#{latitude}[2], #{longitude}[2]);
        var fourth = L.latLng(#{latitude}[0], #{longitude}[0]);
        map.fire("click", { latlng: first });
        map.fire("click", { latlng: second });
        map.fire("click", { latlng: third });
        map.fire("click", { latlng: fourth });
      JS
      sleep 1
      page.execute_script(polygon_add)
      sleep 1
    end

    def drag_marker
      find('div[title="Drag Layers"] a').click
      marker_drag = <<~JS
        var ctrl = $(".picker-wrapper [data-decidim-map]").data("map-controller");
        var marker = ctrl.shapes[Object.keys(ctrl.shapes)[0]];

        marker.setLatLng(L.latLng(13.2, 11.4));
        marker.fire("pm:dragend");
      JS
      sleep 1
      page.execute_script(marker_drag)
      sleep 1
    end

    def drag_line
      find('div[title="Drag Layers"] a').click
      line_drag = <<~JS
        var ctrl = $(".picker-wrapper [data-decidim-map]").data("map-controller");
        var line = ctrl.shapes[Object.keys(ctrl.shapes)[0]];

        line.setLatLngs([
          [11.5, 5],
          [12, 5.5]
        ]);
        line.fire("pm:dragend");
      JS
      sleep 1
      page.execute_script(line_drag)
      sleep 1
    end

    def drag_polygon
      find('div[title="Drag Layers"] a').click
      polygon_drag = <<~JS
        var ctrl = $(".picker-wrapper [data-decidim-map]").data("map-controller");
        var polygon = ctrl.shapes[Object.keys(ctrl.shapes)[0]];

        polygon.setLatLngs([
          [11.5, 5],
          [12, 5.5],
          [12.5, 6]
        ]);
        polygon.fire("pm:dragend");
      JS
      sleep 1
      page.execute_script(polygon_drag)
      sleep 1
    end

    let(:dummy) { create(:dummy_resource, body: "A reasonable body") }
    let(:dummy_form) { Decidim::DummyResources::DummyResourceForm.from_model(dummy) }
    let(:form) { Decidim::FormBuilder.new("dummy", dummy_form, template, {}) }
    let(:map_configuration) { "multiple" }

    let(:cell) { template.cell("decidim/locations/locations", dummy, form: form, map_configuration: map_configuration, coords: [12, 2], checkbox: false) }

    context "when geocoding" do
      # Console.warn print tool
      # puts page.driver.browser.manage.logs.get(:browser).map(&:message).join("\n")
      let(:geocode_response) do
        {
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
      end

      before do
        visit "/test_map"

        # Wait for the map to be rendered
        expect(page).to have_css("[data-decidim-map] .leaflet-map-pane img")

        # Wait for all map tile images to be loaded
        loop do
          break if page.all("[data-decidim-map] .leaflet-map-pane img").all? { |img| img["complete"] == "true" }

          sleep 0.1
        end
      end

      context "when typing locations" do
        it "adds marker" do
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
          expect(page).to have_css(".type-loc-field")
          find("#dummy_address").set("veneen")
          expect(page).to have_content(
            "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
          )
          find("#autoComplete_result_0").click
          click_button "Add"
          expect(page).to have_css(".shape-field")
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
      let(:use_revgeo) { true }

      before do
        visit "/test_map"

        # Wait for the map to be rendered
        expect(page).to have_css("[data-decidim-map] .leaflet-map-pane img")

        # Wait for all map tile images to be loaded
        loop do
          break if page.all("[data-decidim-map] .leaflet-map-pane img").all? { |img| img["complete"] == "true" }

          sleep 0.1
        end
      end

      context "when picking locations" do
        context "when marker" do
          it "adds markers" do
            page.execute_script(revgeo)
            find('div[title="Draw Marker"] a').click
            find("[data-decidim-map]").click(x: 20, y: 10)
            find("div.leaflet-pm-actions-container a.leaflet-pm-action.action-cancel").click
            expect(page).to have_css(".leaflet-marker-icon")
          end
        end

        context "when line" do
          it "adds lines" do
            page.execute_script(revgeo)
            find('div[title="Draw Polyline"] a').click
            find("[data-decidim-map]").click(x: 20, y: 10)
            find("[data-decidim-map]").click(x: 5, y: 2)
            find("div.leaflet-pm-actions-container a.leaflet-pm-action.action-finish").click
            expect(page).to have_css(".leaflet-interactive")
          end
        end

        context "when polygon" do
          it "adds polygon" do
            page.execute_script(revgeo)
            find('div[title="Draw Polygons"] a').click
            find("[data-decidim-map]").click(x: 50, y: 45)
            find("[data-decidim-map]").click(x: 30, y: 37)
            find("[data-decidim-map]").click(x: 33, y: 21)
            find("[data-decidim-map]").click(x: 50, y: 45)
            expect(page).to have_css(".leaflet-interactive")
          end
        end
      end

      context "when shape added and clicked" do
        context "when marker" do
          it "opens a modal that shows the marker's address" do
            page.execute_script(revgeo)
            add_marker
            expect(page).to have_css(".location-address", visible: :hidden)
            find(".leaflet-marker-icon").click
            expect(page).to have_field("address", with: "Veneentekijäntie 4")
            expect(page).to have_content("Save")
          end
        end

        context "when line" do
          it "opens a modal that shows the line's address" do
            page.execute_script(revgeo)
            add_line
            expect(page).to have_css(".location-address", visible: :hidden)
            find(".leaflet-interactive").click
            expect(page).to have_field("address", with: "Veneentekijäntie 4")
            expect(page).to have_content("Save")
          end
        end

        context "when polygon" do
          it "opens a modal that shows the polygon's address" do
            page.execute_script(revgeo)
            add_polygon
            expect(page).to have_css(".location-address", visible: :hidden)
            find(".leaflet-interactive").click
            expect(page).to have_field("address", with: "Veneentekijäntie 4")
            expect(page).to have_content("Save")
          end
        end
      end

      context "when shape dragged" do
        context "when marker" do
          it "updates marker's coordinates" do
            page.execute_script(revgeo)
            add_marker
            drag_marker
            expect(find(".location-latitude", visible: :hidden).value).to eq("13.2")
            expect(find(".location-longitude", visible: :hidden).value).to eq("11.4")
          end
        end

        context "when line" do
          it "updates line's coordinates" do
            page.execute_script(revgeo)
            add_line
            drag_line
            expect(find(".location-latitude", visible: :hidden).value).to eq("11.75")
            expect(find(".location-longitude", visible: :hidden).value).to eq("5.25")
          end
        end

        context "when polygon" do
          it "updates polygon's coordinates" do
            page.execute_script(revgeo)
            add_polygon
            drag_polygon
            expect(find(".location-latitude", visible: :hidden).value).to eq("12")
            expect(find(".location-longitude", visible: :hidden).value).to eq("5.5")
          end
        end
      end

      context "when marker added and it's fetching the address" do
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
          find('div[title="Draw Marker"] a').click
          find("[data-decidim-map]").click(x: 20, y: 10)
          expect(page).to have_content("Fetching address for this shape")
        end

        context "when marker added and it doesn't find an address" do
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
                      def.resolve(response)
                    });
                    return deferred.promise();
                };
              });
            JS
          end

          it "opens a popup that tells the user that the address was not found" do
            page.execute_script(revgeo)
            find('div[title="Draw Marker"] a').click
            find("[data-decidim-map]").click(x: 20, y: 10)
            expect(page).to have_content("No address found for this shape")
          end
        end
      end

      context "when shape deleted from modal" do
        context "when marker" do
          it "deletes the marker from the map" do
            page.execute_script(revgeo)
            add_marker
            expect(page).to have_css(".leaflet-marker-icon", visible: :all)
            find(".leaflet-marker-icon").click
            click_button "Delete shape"
            expect(page).not_to have_css(".leaflet-marker-icon")
          end
        end

        context "when line" do
          it "deletes the line from the map" do
            page.execute_script(revgeo)
            add_line
            expect(page).to have_css(".leaflet-interactive")
            find(".leaflet-interactive").click
            click_button "Delete shape"
            expect(page).not_to have_css(".leaflet-interactive")
          end
        end

        context "when polygon" do
          it "deletes the polygon from the map" do
            page.execute_script(revgeo)
            add_polygon
            expect(page).to have_css(".leaflet-interactive")
            find(".leaflet-interactive").click
            click_button "Delete shape"
            expect(page).not_to have_css(".leaflet-interactive")
          end
        end
      end

      context "when shape deleted from control panel" do
        context "when marker" do
          it "deletes the marker from the map" do
            page.execute_script(revgeo)
            add_marker
            expect(page).to have_css(".leaflet-marker-icon", visible: :all)
            find('div[title="Remove Layers"] a').click
            find(".leaflet-marker-icon").click
            expect(page).not_to have_css(".leaflet-marker-icon")
          end
        end

        context "when line" do
          it "deletes the line from the map" do
            page.execute_script(revgeo)
            add_line
            expect(page).to have_css(".leaflet-interactive")
            find('div[title="Remove Layers"] a').click
            find(".leaflet-interactive").click
            expect(page).not_to have_css(".leaflet-interactive")
          end
        end

        context "when polygon" do
          it "deletes the polygon from the map" do
            page.execute_script(revgeo)
            add_polygon
            expect(page).to have_css(".leaflet-interactive")
            find('div[title="Remove Layers"] a').click
            find(".leaflet-interactive").click
            expect(page).not_to have_css(".leaflet-interactive")
          end
        end
      end

      context "when multiple shapes and one deleted" do
        context "when markers" do
          it "deletes only one" do
            page.execute_script(revgeo)
            add_marker
            add_marker(latitude: 11.523, longitude: 5.523)
            expect(page).to have_css(".leaflet-marker-icon", count: 2)
            find(".leaflet-marker-icon", match: :first).click
            click_button "Delete shape"
            expect(page).to have_css(".leaflet-marker-icon", count: 1)
          end
        end

        context "when lines" do
          it "deletes only one" do
            page.execute_script(revgeo)
            add_line
            add_line(latitude: [60.25240524264372, 60.25116980538645], longitude: [25.10409421539333, 25.104342109680122])
            expect(page).to have_css(".leaflet-interactive", count: 2)
            find(".leaflet-interactive", match: :first).click
            click_button "Delete shape"
            expect(page).to have_css(".leaflet-interactive", count: 1)
          end
        end

        context "when polygons" do
          it "deletes only one" do
            page.execute_script(revgeo)
            add_polygon
            add_polygon(latitude: [85.05109772344434, 85.05101347805167, 85.05106165693364], longitude: [24.741211170645243, 24.7438833903077, 24.74355157804477])
            expect(page).to have_css(".leaflet-interactive", count: 2)
            find(".leaflet-interactive", match: :first).click
            click_button "Delete shape"
            expect(page).to have_css(".leaflet-interactive", count: 1)
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
      let(:use_dummy_random_ids) { true }

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

      let(:before_render) do
        lambda do
          allow(cell).to receive(:random_id).and_return("example")
          allow(cell_two).to receive(:random_id).and_return("exampletwo")
        end
      end

      before do
        visit "/test_map"

        # Wait for the map to be rendered
        expect(page).to have_css("[data-decidim-map] .leaflet-map-pane img")

        # Wait for all map tile images to be loaded
        loop do
          break if page.all("[data-decidim-map] .leaflet-map-pane img").all? { |img| img["complete"] == "true" }

          sleep 0.1
        end
      end

      it "renders multiple maps" do
        expect(page).to have_css(".type-loc-field", count: 2)
        expect(page).to have_selector("div[data-shape-field]", count: 2)
      end

      context "when adding markers" do
        it "adds markers correctly" do
          page.execute_script(revgeo)

          within "#pick_model_locations_map-example" do
            find('div[title="Draw Marker"] a').click
            find("[data-decidim-map]").click(x: 15, y: 25)
            find("[data-decidim-map]").click(x: 20, y: 10)
            find("div.leaflet-pm-actions-container a.leaflet-pm-action.action-cancel").click

            expect(page).to have_css(".leaflet-marker-icon", count: 1)
          end

          page.execute_script("window.scrollBy(0, 800)")

          within "#pick_model_locations_map-exampletwo" do
            find('div[title="Draw Marker"] a').click
            find("[data-decidim-map]").click(x: 15, y: 5)
            find("[data-decidim-map]").click(x: 20, y: 10)
            find("div.leaflet-pm-actions-container a.leaflet-pm-action.action-cancel").click

            expect(page).to have_css("img.leaflet-marker-icon", count: 2)
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
        visit "/test_map"
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
end
