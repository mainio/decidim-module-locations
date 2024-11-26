# frozen_string_literal: true

shared_examples "reverse geocoding" do
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
        click_on "Delete shape"
        expect(page).to have_no_css(".leaflet-marker-icon")
      end
    end

    context "when line" do
      it "deletes the line from the map" do
        page.execute_script(revgeo)
        add_line
        expect(page).to have_css(".leaflet-interactive")
        find(".leaflet-interactive").click
        click_on "Delete shape"
        expect(page).to have_no_css(".leaflet-interactive")
      end
    end

    context "when polygon" do
      it "deletes the polygon from the map" do
        page.execute_script(revgeo)
        add_polygon
        expect(page).to have_css(".leaflet-interactive")
        find(".leaflet-interactive").click
        click_on "Delete shape"
        expect(page).to have_no_css(".leaflet-interactive")
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
        expect(page).to have_no_css(".leaflet-marker-icon")
      end
    end

    context "when line" do
      it "deletes the line from the map" do
        page.execute_script(revgeo)
        add_line
        expect(page).to have_css(".leaflet-interactive")
        find('div[title="Remove Layers"] a').click
        find(".leaflet-interactive").click
        expect(page).to have_no_css(".leaflet-interactive")
      end
    end

    context "when polygon" do
      it "deletes the polygon from the map" do
        page.execute_script(revgeo)
        add_polygon
        expect(page).to have_css(".leaflet-interactive")
        find('div[title="Remove Layers"] a').click
        find(".leaflet-interactive").click
        expect(page).to have_no_css(".leaflet-interactive")
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
        click_on "Delete shape"
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
        click_on "Delete shape"
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
        click_on "Delete shape"
        expect(page).to have_css(".leaflet-interactive", count: 1)
      end
    end
  end
end
