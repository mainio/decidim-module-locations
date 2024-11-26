# frozen_string_literal: true

shared_examples "type locations" do
  context "when adding single location" do
    it "adds marker" do
      expect(page).to have_css(".type-loc-field")
      sleep 1
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
      sleep 1
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
      sleep 1
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
