import getDistanceBetweenPoints from "./avg_coordinates.js";
import addMarkerField from "./add_marker_field.js";
import initializeTabs from "./initialize_tabs.js";

export default () => {
  const addInputGroup = (markerFieldContainer, addressData, wrapperEl) => {
    const markerId = addressData.markerId;
    const address = addressData.address;
    const lat = addressData.position.lat;
    const lng = addressData.position.lng;

    const markerField = markerFieldContainer.querySelector(`[data-marker-id="${markerId}"]`);
    if (markerField.hasChildNodes()) {
      const oldCoords = [markerField.querySelector(".location-latitude").value, markerField.querySelector(".location-longitude").value];
      const newCoords = [lat, lng];
      const markerRadius = getDistanceBetweenPoints(oldCoords, newCoords);

      if (markerRadius < 200) {
        markerField.querySelector(".location-latitude").value = lat;
        markerField.querySelector(".location-longitude").value = lng;
      } else {
        markerField.querySelector(".location-address").value = address;
        markerField.querySelector(".location-latitude").value = lat;
        markerField.querySelector(".location-longitude").value = lng;
      }
    } else {
      const template = wrapperEl.querySelector(`#model_input_template${wrapperEl.querySelector("[data-decidim-map]").id}`);
      const clone = template.content.cloneNode(true);
      let input = clone.querySelectorAll("input");
      input[0].name = input[0].name.replace("%index%", markerId)
      input[0].value = address;
      input[1].name = input[1].name.replace("%index%", markerId);
      input[1].value = lat;
      input[2].name = input[2].name.replace("%index%", markerId);
      input[2].value = lng;

      markerField.appendChild(clone);
    }
  };

  const coordAverage = (markerFieldContainer, wrapperEl) => {
    const latArr = Array.from(markerFieldContainer.querySelectorAll(".location-latitude"));
    const latitudes = [];
    latArr.map((val) => latitudes.push(parseFloat(val.value)));
    let latAvg = latitudes.reduce((pv, cv) => pv + cv, 0);
    latAvg /= latitudes.length;

    const lngArr = Array.from(markerFieldContainer.querySelectorAll(".location-longitude"));
    const longitudes = [];
    lngArr.map((val) => longitudes.push(parseFloat(val.value)));
    let lngAvg = longitudes.reduce((pv, cv) => pv + cv, 0);
    lngAvg /= longitudes.length;

    if (isNaN(latAvg) && isNaN(lngAvg)) {
      latAvg = null;
      lngAvg = null;
    }

    wrapperEl.querySelector(".model-latitude").value = latAvg;
    wrapperEl.querySelector(".model-longitude").value = lngAvg;
  };

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
      ctrl.unbindPopUp(addressData.markerId);
      addInputGroup(markerFieldContainer, addressData, wrapperEl);
      if (averageInput) {
        coordAverage(markerFieldContainer, wrapperEl);
      }
    });

    $(mapEl).on("no-address", (_ev, addressData) => {
      ctrl.deleteMarker(addressData.markerId);
      markerFieldContainer.querySelector(`[data-marker-id="${addressData.markerId}"]`).remove();
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
    ctrl.setEventHandler("markeradd", (marker, ev) => {
      const markerId = marker.options.id;

      if (mapConfig && mapConfig === "single" && (ev === "typeEv" || ev === "clickEv")) {
        const oldMarker = markerFieldContainer.querySelector(".marker-field");
        if (oldMarker) {
          ctrl.deleteMarker(oldMarker.dataset.markerId);
          markerFieldContainer.querySelector(`[data-marker-id="${oldMarker.dataset.markerId}"]`).remove();
        };
      };
      addMarkerField(markerFieldContainer, markerId);
      if (ev === "clickEv") {
        ctrl.bindPopUp(markerId);
        $(mapEl).trigger("geocoder-reverse.decidim", [marker.getLatLng(), { markerId }]);
      };

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

        // With Foundation we have to use jQuery
        $(editModalEl).foundation("open");
      });

      marker.on("dragend", () => {
        $(mapEl).trigger("geocoder-reverse.decidim", [marker.getLatLng(), { markerId }]);
        setTimeout(() => {
          ctrl.enablePlaceMarkers();
        }, 100)
      })

      marker.on("dragstart", () => {
        ctrl.disablePlaceMarkers();
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
    initializeTabs(wrapperEl);
  });
};
