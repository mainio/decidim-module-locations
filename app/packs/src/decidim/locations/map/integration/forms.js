import addMarkerField from "./add_marker_field.js";
import addInputGroup from "./add_input_group.js";
import coordAverage from "./coord_average.js";
import centerShape from "./center_shape.js";

export default () => {
  document.querySelectorAll("[data-location-picker]").forEach((wrapperEl) => {
    const options = JSON.parse(wrapperEl.dataset.locationPicker);
    const mapEl = wrapperEl.querySelector("[data-decidim-map]");
    const ctrl = $(mapEl).data("map-controller");
    const editModalEl = document.querySelector(options.revealSelector);
    const markerFieldContainer = wrapperEl.querySelector("[data-marker-field]");
    const locFields = editModalEl.querySelector(".location-fields");
    const modalButtons = editModalEl.querySelector("[data-modal-buttons]");
    const typeLocWrap = wrapperEl.querySelector(".type-locations-wrapper");
    const typeLocInput = typeLocWrap.querySelector(".type-loc-field");
    const typeLocButton = typeLocWrap.querySelector(".type-loc-button");
    const locationCheckBox = wrapperEl.querySelector(["[has_location]", "has_location"].map((suffix) => `input[type="checkbox"][name$="${suffix}"]`));
    const modelLoc = wrapperEl.querySelector(".picker-wrapper");
    const containerMarkerField = markerFieldContainer.querySelectorAll(".marker-field");
    const mapConfig = mapEl.dataset.mapConfiguration
    const averageInput = wrapperEl.querySelector(".model-longitude") && wrapperEl.querySelector(".model-latitude")

    const locationCheck = () => {
      if (locationCheckBox && locationCheckBox.checked) {
        modelLoc.classList.remove("hide");
        ctrl.map.invalidateSize();
      } else {
        modelLoc.classList.add("hide");
      }
    };

    if (locationCheckBox === null) {
      modelLoc.classList.remove("hide")
      ctrl.map.invalidateSize();
    } else {
      locationCheck();
      locationCheckBox.addEventListener("change", () => {
        locationCheck();
      });
    }

    let displayList = true;

    typeLocInput.addEventListener("input", () => {
      if (typeLocInput.value === "") {
        displayList = true;
      }
    })

    $(typeLocInput).on("open", function () {
      if (displayList === false) {
        typeLocInput.ac.close();
      }
    });

    let geocodingTimeout = null;
    let typeLocCoords = null;

    $(typeLocInput).on("geocoder-suggest-coordinates.decidim", (_ev, coordinates) => {
      clearTimeout(geocodingTimeout);
      geocodingTimeout = setTimeout(() => {
        typeLocWrap.querySelector(".hint").classList.remove("hide");
        ctrl.setView(coordinates);
        typeLocCoords = coordinates;
        typeLocButton.disabled = false;
        displayList = false;
      }, 300);
    });

    typeLocButton.addEventListener("click", (event) => {
      event.preventDefault()
      const markerId = ctrl.addMarker(typeLocCoords, "typeEv");
      const addressData = { address: typeLocInput.value, position: {lat: typeLocCoords[0], lng: typeLocCoords[1]}, markerId };
      typeLocInput.value = "";
      typeLocWrap.querySelector(".hint").classList.add("hide");
      displayList = true;
      typeLocButton.disabled = true;
      addInputGroup(markerFieldContainer, addressData, wrapperEl);
      if (averageInput) {
        coordAverage(markerFieldContainer, wrapperEl);
      }
    });

    $(mapEl).on("marker-address", (_ev, addressData) => {
      if (addressData.shape === "Marker") {
        ctrl.unbindPopUp(addressData.markerId);
      };

      addInputGroup(markerFieldContainer, addressData, wrapperEl);
      if (averageInput) {
        coordAverage(markerFieldContainer, wrapperEl);
      }
    });

    $(mapEl).on("no-address", (_ev, addressData) => {
      if (addressData.shape === "Marker") {
        ctrl.unbindPopUp(addressData.markerId);
      };

      addInputGroup(markerFieldContainer, addressData, wrapperEl);
      if (averageInput) {
        coordAverage(markerFieldContainer, wrapperEl);
      };
    });

    editModalEl.querySelector("[data-delete-marker]").addEventListener("click", () => {
      const markerId = editModalEl.dataset.markerId;
      const inputDiv = markerFieldContainer.querySelector(`[data-marker-id="${markerId}"]`);
      ctrl.deleteMarker(markerId);
      if (inputDiv) {
        inputDiv.remove();
      };
      if (averageInput) {
        coordAverage(markerFieldContainer, wrapperEl);
      };
      $(editModalEl).foundation("close");
    });

    modalButtons.querySelector("[data-modal-save]").addEventListener("click", () => {
      const markerId = editModalEl.dataset.markerId;
      const inputDiv = markerFieldContainer.querySelector(`[data-marker-id="${markerId}"]`);
      const modalAddress = locFields.querySelector("[data-modal-address]");
      if (inputDiv) {
        inputDiv.querySelector(".location-address").value = modalAddress.value;
      };
      $(editModalEl).foundation("close");
    });

    ctrl.map.on("pm:create", (event) => {
      event.marker.options.id = Math.random().toString(36).slice(2, 9);
      if (event.marker.pm._shape === "Marker") {
        ctrl.markers[event.marker.options.id] = event.marker;
      };
      ctrl.triggerEvent("markeradd", [event.marker, "clickEv"])
    });

    ctrl.map.on("pm:remove", (event) => {
      markerFieldContainer.querySelector(`[data-marker-id="${event.layer.options.id}"]`).remove();
    });

    let removalMode = false;
    let drawMode = false;
    let dragMode = false;
    let editMode = false;

    ctrl.map.on("pm:globalremovalmodetoggled", (event) => {
      removalMode = event.enabled;
    });

    ctrl.map.on("pm:globaldrawmodetoggled", (event) => {
      drawMode = event.enabled;
    });

    ctrl.map.on("pm:globaldragmodetoggled", (event) => {
      dragMode = event.enabled;
    });

    ctrl.map.on("pm:globaleditmodetoggled", (event) => {
      editMode = event.enabled;
    });

    ctrl.setEventHandler("markeradd", (marker, ev) => {
      const markerId = marker.options.id;
      const shape = marker.pm._shape;
      let coordinates = null;
      let shapeCoordinates = null;

      if (ev !== "editEv") {
        if (mapConfig && mapConfig === "single" && (ev === "typeEv" || ev === "clickEv")) {
          const oldMarker = markerFieldContainer.querySelector(".marker-field");
          if (oldMarker) {
            ctrl.deleteMarker(oldMarker.dataset.markerId);
            markerFieldContainer.querySelector(`[data-marker-id="${oldMarker.dataset.markerId}"]`).remove();
          };
        };
        addMarkerField(markerFieldContainer, markerId);
        if (ev === "clickEv") {
          if (shape === "Marker") {
            ctrl.bindPopUp(markerId);
            coordinates = marker.getLatLng();
          } else if (shape === "Line" || shape === "Polygon") {
            shapeCoordinates = marker._latlngs;
            coordinates = centerShape(marker._latlngs, shape);
          };

          $(mapEl).trigger("geocoder-reverse.decidim", [coordinates, { markerId, shape, shapeCoordinates }]);
        };
      };

      if (shape === "Marker") {
        marker.on("click", () => {
          editModalEl.dataset.markerId = markerId;

          const inputDiv = markerFieldContainer.querySelector(`[data-marker-id="${markerId}"]`);
          if (inputDiv && !inputDiv.hasChildNodes()) {
            // When the `inputDiv`'s input fields have not been added yet, the reverse geocoding
            // is not completed yet, so the user cannot edit the address yet.
            return;
          } else if (inputDiv && inputDiv.hasChildNodes()) {
            editModalEl.querySelector(".location-fields input[name=address]").value = inputDiv.querySelector(".location-address").value;
          } else {
            locFields.querySelector("[data-modal-address]").setAttribute("disabled", true);
            modalButtons.querySelector("[data-modal-save]").setAttribute("disabled", true);
          };
          if (!removalMode && !drawMode && !dragMode && !editMode) {
          // With Foundation we have to use jQuery
            $(editModalEl).foundation("open");
          };
        });
      };

      marker.on("pm:dragend", () => {
        if (shape === "Marker") {
          $(mapEl).trigger("geocoder-reverse.decidim", [marker.getLatLng(), { markerId, shape }]);
        } else if (shape === ("Line" || "Polygon")) {
          $(mapEl).trigger("geocoder-reverse.decidim", [centerShape(marker._latlngs, shape), { markerId, shape, shapeCoordinates }]);
        };
      })
    });

    if (containerMarkerField.length > 0) {
      const bounds = [];
      containerMarkerField.forEach(
        (locContainer) => {
          let lat = parseFloat(locContainer.querySelector(".location-latitude").value);
          let lng = parseFloat(locContainer.querySelector(".location-longitude").value);
          ctrl.addMarker([lat, lng], "editEv", locContainer.dataset.markerId);
          bounds.push([lat, lng]);
        }
      )
      const area = new L.LatLngBounds(bounds)
      ctrl.map.fitBounds(area);
    }
  });
};
