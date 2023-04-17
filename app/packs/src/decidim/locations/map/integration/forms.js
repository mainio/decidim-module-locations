import getDistanceBetweenPoints from "./avg_coordinates.js"

const initializeTabs = (wrapperEl) => {
  const mapEl = wrapperEl.querySelector("[data-decidim-map]");
  const ctrl = $(mapEl).data("map-controller");
  const tabsEl = wrapperEl.querySelector('[data-map-container="#pick_model_locations_map"]');
  const typeLocWrapperEl = wrapperEl.querySelector(".type-locations-wrapper");
  const mainTabs = tabsEl.querySelectorAll(":scope > li");
  const moreTabs = tabsEl.querySelector("[data-more-tabs]").querySelectorAll(":scope > li")
  const transparentActions = ["clear-markers"];

  let activeTab = null;

  const setActiveTab = (action) => {
    const wasActivated = activeTab === action;

    if (wasActivated) {
      activeTab = null;
    } else {
      mainTabs.forEach((li) => li.classList.remove("is-active"));
      activeTab = action;
    }

    const activeLi = tabsEl.querySelector(`:scope > li[data-action="${action}"]`);
    if (activeLi) {
      if (wasActivated) {
        activeLi.classList.remove("is-active");
      } else {
        activeLi.classList.add("is-active");
      }
    }
  };

  const handleActionTab = (action) => {
    const wasActivated = activeTab === action;

    if (!transparentActions.includes(action)) {
      setActiveTab(action);

      ctrl.disablePlaceMarkers();
      typeLocWrapperEl.classList.add("hide");
      if (wasActivated) {
        return;
      }
    }

    if (action === "add-markers") {
      ctrl.enablePlaceMarkers();
    } else if (action === "type-loc") {
      typeLocWrapperEl.classList.remove("hide");
    } else if (action === "clear-markers") {
      ctrl.clearMarkers();
    }
  };

  if (Object.keys(ctrl.markers).length === 0) {
    handleActionTab("add-markers");
  }

  mainTabs.forEach((li) => {
    const action = li.dataset.action;
    if (action === "more") {
      return;
    }

    li.querySelector(":scope > a").addEventListener("click", (ev) => {
      ev.preventDefault();
      handleActionTab(action);
    });
  });

  moreTabs.forEach((li) => {
    const action = li.dataset.action;
    li.querySelector(":scope > a").addEventListener("click", (ev) => {
      ev.preventDefault();
      handleActionTab(action);
    })
  });
};

export default () => {
  const addInputGroup = (markerFieldContainer, addressData) => {
    const markerId = addressData.markerId;
    const address = addressData.address;
    const lat = addressData.position.lat;
    const lng = addressData.position.lng;

    const markerField = markerFieldContainer.querySelector(`[data-marker-id="${markerId}"]`);
    if (markerField) {
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
      const container = document.createElement("div");
      container.setAttribute("class", "marker-field");
      container.dataset.markerId = markerId;

      const template = document.querySelector("#model_input_template");
      const clone = template.content.cloneNode(true);
      let input = clone.querySelectorAll("input");
      input[0].value = address;
      input[1].value = lat;
      input[2].value = lng;

      container.appendChild(clone);
      markerFieldContainer.appendChild(container);
    }
  };

  const coordAverage = (markerFieldContainer) => {
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

    document.querySelector(".model-latitude").value = latAvg;
    document.querySelector(".model-longitude").value = lngAvg;
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
    const locationCheckBox = document.getElementById("model_has_location");
    const modelLoc = document.getElementById("model_locations");
    const containerMarkerField = markerFieldContainer.querySelectorAll(".marker-field");

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

    typeLocButton.addEventListener("click", () => {
      const markerId = ctrl.addMarker(typeLocCoords, "typeEv");
      const addressData = { address: typeLocInput.value, position: {lat: typeLocCoords[0], lng: typeLocCoords[1]}, markerId };
      typeLocInput.value = "";
      typeLocWrap.querySelector(".hint").classList.add("hide");
      displayList = true;
      typeLocButton.disabled = true;
      addInputGroup(markerFieldContainer, addressData);
      coordAverage(markerFieldContainer);
    });

    $(mapEl).on("marker-address", (_ev, addressData) => {
      ctrl.unbindPopUp(addressData.markerId);
      addInputGroup(markerFieldContainer, addressData);
      coordAverage(markerFieldContainer);
    });

    editModalEl.querySelector("[data-delete-marker]").addEventListener("click", () => {
      const markerId = editModalEl.dataset.markerId;
      const inputDiv = markerFieldContainer.querySelector(`[data-marker-id="${markerId}"]`);
      ctrl.deleteMarker(markerId);
      inputDiv.remove();
      $(editModalEl).foundation("close");
    });

    modalButtons.querySelector("[data-modal-save]").addEventListener("click", () => {
      const markerId = editModalEl.dataset.markerId;
      const inputDiv = markerFieldContainer.querySelector(`[data-marker-id="${markerId}"]`);
      const modalAddress = locFields.querySelector("[data-modal-address]").value;

      inputDiv.querySelector(".location-address").value = modalAddress;
      $(editModalEl).foundation("close");
    });

    ctrl.setEventHandler("markeradd", (marker, ev) => {
      const markerId = marker.options.id;
      if (ev === "clickEv") {
        ctrl.bindPopUp(markerId);
        $(mapEl).trigger("geocoder-reverse.decidim", [marker.getLatLng(), { markerId }]);
      }

      marker.on("click", () => {
        editModalEl.dataset.markerId = markerId;

        const inputDiv = markerFieldContainer.querySelector(`[data-marker-id="${markerId}"]`);
        if (!inputDiv) {
          // When the `inputDiv` has not yet been added, the reverse geocoding
          // is not completed yet, so the user cannot edit the address yet.
          return;
        }
        editModalEl.querySelector(".location-fields input[name=address]").value = inputDiv.querySelector(".location-address").value;

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

    if (locationCheckBox !== null) {
      locationCheck();
    }

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
