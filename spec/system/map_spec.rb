# frozen_string_literal: true

require "spec_helper"

describe "Map" do
  let!(:organization) { create(:organization) }

  let(:template_class) do
    Class.new(ActionView::Base) do
      include Cell::RailsExtensions::ActionView

      delegate :snippets, :current_organization, to: :controller

      def protect_against_forgery?
        false
      end

      # Fix issue with passing the correct view context to the cells. Otherwise
      # the script tags are added to incorrect context and therefore not
      # rendered.
      def cell(name, model, options = {}, &)
        options = { context: { view_context: self } }.deep_merge(options)
        super(name, model, options, &)
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
      12, "Title of the marker", "Summary of the record", "Body text of the record", "Foobar street 123",
      60.25013831397032, 25.11058330535889, "Point",
      '{"type":"Feature",
      "geometry":{"type":"Point",
      "coordinates":[60.25013831397032, 25.11058330535889]}}'
    ]]
  end

  let(:line) do
    [[
      13, "Title of the line", "Summary of the record", "Body text of the record", "Foobar street 123",
      60.241787524015265, 25.11521816253662, "LineString",
      '{"type":"Feature",
      "geometry":{"type":"LineString",
      "coordinates":[[60.24240524264389,25.10809421539307],
      [60.24116980538663,25.122342109680176]]}}'
    ]]
  end

  let(:polygon) do
    [[
      23, "Title of the polygon", "Summary of the record", "Body text of the record", "Foobar street 123",
      60.2455574969813, 25.109066963195804, "Polygon",
      '{"type":"Feature",
      "geometry":{"type":"Polygon",
      "coordinates":[[[60.24721874334426,25.109295845031742],
      [60.24381102836454,25.114445686340336],
      [60.2456427192351,25.103459358215336]]]}}'
    ]]
  end

  let(:all_shapes) do
    [
      [
        12, "Title of the marker", "Summary of the record", "Body text of the record", "Foobar street 123",
        60.25013831397032, 25.11058330535889, "Point",
        '{"type":"Feature",
        "geometry":{"type":"Point",
        "coordinates":[60.25013831397032, 25.11058330535889]}}'
      ],
      [
        13, "Title of the line", "Summary of the record", "Body text of the record", "Foobar street 123",
        60.241787524015265, 25.11521816253662, "LineString",
        '{"type":"Feature",
        "geometry":{"type":"LineString",
        "coordinates":[[60.24240524264389,25.10809421539307],
        [60.24116980538663,25.122342109680176]]}}'
      ],
      [
        23, "Title of the polygon", "Summary of the record", "Body text of the record", "Foobar street 123",
        60.2455574969813, 25.109066963195804, "Polygon",
        '{"type":"Feature",
        "geometry":{"type":"Polygon",
        "coordinates":[[[60.24721874334426,25.109295845031742],
        [60.24381102836454,25.114445686340336],
        [60.2456427192351,25.103459358215336]]]}}'
      ]
    ]
  end

  let(:cell) { template.cell("decidim/locations/map", shapes) }
  let(:javascript) { template.javascript_pack_tag("decidim_core", defer: false) }
  let(:styles) do
    css = <<~CSS
      .cellwrap{
        aspect-ratio: 21/9;
      }
      .cellwrap > *{
        height: 100%;
      }
    CSS
    %(<style type="text/css">\n#{css}</style>)
  end

  let(:html_document) do
    cell_html = cell.to_s
    css = styles
    js = javascript
    template.instance_eval do
      <<~HTML.strip
        <!doctype html>
        <html lang="en">
        <head>
          <title>Map Test</title>
          #{stylesheet_pack_tag "decidim_core", media: "all"}
          #{css}
        </head>
        <body>
          <header>
            <a href="#content">Skip to main content</a>
          </header>
          <div class="cellwrap">
            #{cell_html}
          </div>
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
      utility = Decidim::Map.autocomplete(organization:)
      allow(Decidim::Map).to receive(:autocomplete).with(organization:).and_return(utility)
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

      get "/favicon.ico", to: ->(_) { [200, {}, []] }
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
      visit_test_map
    end

    it_behaves_like "map cell render"
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
      marker_drag = <<~JS
        var ctrl = $(".picker-wrapper [data-decidim-map]").data("map-controller");
        var marker = ctrl.shapes[Object.keys(ctrl.shapes)[0]];

        marker.setLatLng([13.2, 11.4]);
        marker.fire("pm:dragend");
      JS
      sleep 1
      page.execute_script(marker_drag)
      sleep 1
    end

    def drag_line
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
    let(:dummy_form) { Decidim::Dev::DummyResourceForm.from_model(dummy) }
    let(:form) { Decidim::FormBuilder.new("dummy", dummy_form, template, {}) }
    let(:map_configuration) { "multiple" }

    let(:cell) { template.cell("decidim/locations/locations", dummy, form:, map_configuration:, coords: [12, 2]) }
    let(:styles) { nil }

    context "when geocoding" do
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
        visit_test_map
      end

      context "when typing locations" do
        context "when adding single location" do
          it "adds marker" do
            expect(page).to have_css(".type-loc-field")
            find_by_id("dummy_address").set("veneen")
            expect(page).to have_content(
              "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
            )
            find_by_id("autoComplete_result_0").click
            click_on "Add"
            expect(page).to have_css(".leaflet-marker-draggable")
          end
        end

        context "when adding multiple locations" do
          it "adds multiple if configured accordingly" do
            expect(page).to have_css(".type-loc-field")
            find_by_id("dummy_address").set("veneen")
            expect(page).to have_content(
              "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
            )
            find_by_id("autoComplete_result_0").click
            click_on "Add"
            expect(page).to have_css(".leaflet-marker-draggable")
            expect(page).to have_css(".leaflet-marker-draggable", count: 1)
            find_by_id("dummy_address").set("veneen")
            expect(page).to have_content(
              "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
            )
            find_by_id("autoComplete_result_1").click
            click_on "Add"
            expect(page).to have_css(".leaflet-marker-draggable")
            expect(page).to have_no_css(".leaflet-marker-draggable", count: 1)
            expect(page).to have_css(".leaflet-marker-draggable", count: 2, visible: :all)
          end
        end

        context "when adding multiple locations and configuration limits it" do
          let(:map_configuration) { "single" }

          it "adds a single location" do
            expect(page).to have_css(".type-loc-field")
            find_by_id("dummy_address").set("veneen")
            expect(page).to have_content(
              "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
            )
            find_by_id("autoComplete_result_0").click
            click_on "Add"
            expect(page).to have_css(".shape-field")
            expect(page).to have_css(".leaflet-marker-draggable", count: 1)
            expect(page).to have_field("dummy_locations__index__address", type: :hidden, with: "Veneentekijäntie 4, Finland")
            find_by_id("dummy_address").set("veneen")
            expect(page).to have_content(
              "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
            )
            find_by_id("autoComplete_result_1").click
            click_on "Add"
            expect(page).to have_field("dummy_locations__index__address", type: :hidden, with: "Veneentekijäntie 6, Finland")
            expect(page).to have_css(".leaflet-marker-draggable", count: 1)
          end
        end

        context "when adding a location and changing its address from the modal" do
          it "changes the address field to the form" do
            expect(page).to have_css(".type-loc-field")
            find_by_id("dummy_address").set("veneen")
            expect(page).to have_content(
              "Veneentekijäntie 4, Finland\nVeneentekijäntie 6, Finland\nVeneentekijäntie 7, Finland"
            )
            find_by_id("autoComplete_result_0").click
            click_on "Add"
            expect(page).to have_css("input[value=\"Veneentekijäntie 4, Finland\"]", visible: :hidden)
            find(".leaflet-marker-draggable").click
            find("input[name=\"address\"]").fill_in with: "Example street"
            click_on "Save"
            expect(page).to have_css("input[value=\"Example street\"]", visible: :hidden)
          end
        end
      end
    end

    context "when reverse geocoding" do
      let(:use_revgeo) { true }

      before do
        visit_test_map
      end

      it_behaves_like "reverse geocoding"
    end

    context "when rendering more than one cell" do
      let(:dummy) { create(:dummy_resource, body: "A reasonable body") }
      let(:dummy_form) { Decidim::Dev::DummyResourceForm.from_model(dummy) }
      let(:form) { Decidim::FormBuilder.new("dummy", dummy_form, template, {}) }
      let(:cell) { template.cell("decidim/locations/locations", dummy, form:, map_configuration: "single", coords: [12, 2]) }
      let(:cell_two) { template.cell("decidim/locations/locations", dummy, form:, map_configuration: "multiple", coords: [12, 2]) }
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
        visit_test_map
      end

      it "renders multiple maps" do
        expect(page).to have_css(".type-loc-field", count: 2)
        expect(page).to have_css("div[data-shape-field]", count: 2)
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

          page.execute_script("window.scrollBy(0, 1100)")

          within "#pick_model_locations_map-exampletwo" do
            find('div[title="Draw Marker"] a').click
            find("[data-decidim-map]").click(x: 6, y: 2)
            find("[data-decidim-map]").click(x: 6, y: 2)

            expect(page).to have_css("img.leaflet-marker-icon", count: 2)
          end
        end
      end
    end

    context "when cell has 'has location' -checkbox" do
      let(:dummy) { create(:dummy_resource, body: "A reasonable body") }
      let(:dummy_form) { Decidim::Dev::DummyResourceForm.from_model(dummy) }
      let(:form) { Decidim::FormBuilder.new("dummy", dummy_form, template, {}) }
      let(:map_configuration) { "multiple" }
      let(:cell) { template.cell("decidim/locations/locations", dummy, form:, map_configuration:, coords: [12, 2], checkbox: true) }

      before do
        visit "/test_map"
      end

      it "checks the box if text is clicked" do
        expect(page).to have_content("Has location")
        expect(page).to have_no_css("[data-decidim-map] .leaflet-map-pane img")

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

def visit_test_map
  visit "/test_map"

  # Wait for the map to be rendered
  expect(page).to have_css("[data-decidim-map] .leaflet-map-pane img")

  # Wait for all map tile images to be loaded
  loop do
    break if page.all("[data-decidim-map] .leaflet-map-pane img").all? { |img| img["complete"] == "true" }

    sleep 0.1
  end
end
