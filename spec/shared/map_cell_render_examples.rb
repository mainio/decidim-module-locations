# frozen_string_literal: true

shared_examples "map cell render" do
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
      expect(page).to have_css('img[title="Title of the marker"]')
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
