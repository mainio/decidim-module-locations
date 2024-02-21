import addShapeField from "./add_shape_field.js";
import addInputGroup from "./add_input_group.js";
import coordAverage from "./coord_average.js";
import centerShape from "./center_shape.js";
import validJson from "./valid_json.js";

export default () => {
  document.querySelectorAll("[data-location-picker]").forEach((wrapperEl) => {
    const options = JSON.parse(wrapperEl.dataset.locationPicker);
    const mapEl = wrapperEl.querySelector("[data-decidim-map]");
    const ctrl = $(mapEl).data("map-controller");
    const editModalEl = document.querySelector(options.revealSelector);
    const shapeFieldContainer = wrapperEl.querySelector("[data-shape-field]");
    const locFields = editModalEl.querySelector(".location-fields");
    const modalButtons = editModalEl.querySelector("[data-modal-buttons]");
    const typeLocWrap = wrapperEl.querySelector(".type-locations-wrapper");
    const typeLocInput = typeLocWrap.querySelector(".type-loc-field");
    const typeLocButton = typeLocWrap.querySelector(".type-loc-button");
    const locationCheckBox = wrapperEl.querySelector(["[has_location]", "has_location"].map((suffix) => `input[type="checkbox"][name$="${suffix}"]`));
    const modelLoc = wrapperEl.querySelector(".picker-wrapper");
    const containerShapeField = shapeFieldContainer.querySelectorAll(".shape-field");
    const mapConfig = mapEl.dataset.mapConfiguration
    const averageInput = wrapperEl.querySelector(".model-longitude") && wrapperEl.querySelector(".model-latitude")
    const clear = wrapperEl.querySelector('[data-action="clear-shapes"]')

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

    clear.addEventListener("click", (event) => {
      event.preventDefault();
      ctrl.clearShapes();
    })

    typeLocButton.addEventListener("click", (event) => {
      event.preventDefault();
      const shapeId = ctrl.addMarker(typeLocCoords, "typeEv");
      const addressData = {
        address: typeLocInput.value,
        position: { lat: typeLocCoords[0], lng: typeLocCoords[1] },
        shapeId: shapeId,
        objectShape: "Point",
        coordinates: { lat: typeLocCoords[0], lng: typeLocCoords[1] }
      };
      typeLocInput.value = "";
      typeLocWrap.querySelector(".hint").classList.add("hide");
      displayList = true;
      typeLocButton.disabled = true;
      addInputGroup(shapeFieldContainer, addressData, wrapperEl);
      if (averageInput) {
        coordAverage(shapeFieldContainer, wrapperEl);
      }
    });

    $(mapEl).on("shape-address", (_ev, addressData) => {
      ctrl.unbindPopup(addressData.shapeId);
      addInputGroup(shapeFieldContainer, addressData, wrapperEl);
      if (averageInput) {
        coordAverage(shapeFieldContainer, wrapperEl);
      }
    });

    $(mapEl).on("no-address", (_ev, addressData) => {
      ctrl.unbindPopup(addressData.shapeId);
      ctrl.bindNoDataPopup(addressData.shapeId);
      addInputGroup(shapeFieldContainer, addressData, wrapperEl);
      if (averageInput) {
        coordAverage(shapeFieldContainer, wrapperEl);
      };
      shapeFieldContainer.querySelector(`[data-shape-id="${addressData.shapeId}"]`).querySelector(
        ".location-address").value = "No address found";
    });

    editModalEl.querySelector("[data-delete-shape]").addEventListener("click", () => {
      const shapeId = editModalEl.dataset.shapeId;
      const inputDiv = shapeFieldContainer.querySelector(`[data-shape-id="${shapeId}"]`);
      ctrl.deleteShape(shapeId);
      if (inputDiv) {
        inputDiv.remove();
      };
      if (averageInput) {
        coordAverage(shapeFieldContainer, wrapperEl);
      };
      $(editModalEl).foundation("close");
    });

    modalButtons.querySelector("[data-modal-save]").addEventListener("click", () => {
      const shapeId = editModalEl.dataset.shapeId;
      const inputDiv = shapeFieldContainer.querySelector(`[data-shape-id="${shapeId}"]`);
      const modalAddress = locFields.querySelector("[data-modal-address]");
      if (inputDiv) {
        inputDiv.querySelector(".location-address").value = modalAddress.value;
      };
      $(editModalEl).foundation("close");
    });

    ctrl.map.on("pm:create", (event) => {
      event.marker.options.id = Math.random().toString(36).slice(2, 9);
      ctrl.shapes[event.marker.options.id] = event.marker;
      ctrl.triggerEvent("shapeadd", [event.marker, "clickEv"])
    });

    ctrl.map.on("pm:remove", (event) => {
      shapeFieldContainer.querySelector(`[data-shape-id="${event.layer.options.id}"]`).remove();
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

    ctrl.setEventHandler("shapeadd", (shape, ev) => {
      const shapeId = shape.options.id;
      let objectShape = shape.pm._shape;

      if (objectShape === "Marker") {
        objectShape = "Point";
      } else if (objectShape === "Line") {
        objectShape = "LineString";
      }

      let coordinates = null;

      if (ev !== "editEv") {
        if (mapConfig && mapConfig === "single" && (ev === "typeEv" || ev === "clickEv")) {
          const oldShape = shapeFieldContainer.querySelector(".shape-field");
          if (oldShape) {
            ctrl.deleteShape(oldShape.dataset.shapeId);
            shapeFieldContainer.querySelector(`[data-shape-id="${oldShape.dataset.shapeId}"]`).remove();
          };
        };
        addShapeField(shapeFieldContainer, shapeId);
        if (ev === "clickEv") {
          if (objectShape === "Point") {
            coordinates = shape.getLatLng();
          } else if (objectShape === "LineString" || objectShape === "Polygon") {
            coordinates = shape._latlngs;
          };
          ctrl.bindFetchPopup(shapeId);
          $(mapEl).trigger("geocoder-reverse.decidim", [centerShape(coordinates, objectShape), { shapeId, objectShape, coordinates }]);
        };
      };

      shape.on("click", () => {
        editModalEl.dataset.shapeId = shapeId;
        ctrl.unbindPopup(shapeId);

        const inputDiv = shapeFieldContainer.querySelector(`[data-shape-id="${shapeId}"]`);
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

      shape.on("pm:dragend", () => {
        ctrl.bindFetchPopup(shapeId);

        if (objectShape === "Point") {
          $(mapEl).trigger("geocoder-reverse.decidim", [shape.getLatLng(), { shapeId, objectShape }]);
        } else if (objectShape === "Polygon" || objectShape === "LineString") {
          coordinates = shape._latlngs;
          $(mapEl).trigger("geocoder-reverse.decidim", [centerShape(shape._latlngs, objectShape), { shapeId, objectShape, coordinates }]);
        };
      })
    });

    if (containerShapeField.length > 0) {
      const bounds = [];
      containerShapeField.forEach(
        (locContainer) => {
          const objectShape = locContainer.querySelector(".location-shape").value;
          const geojson = locContainer.querySelector(".location-geojson").value;
          if (validJson(geojson)) {
            let valid = true;

            if (objectShape === "Point") {
              const markerGeoJson = JSON.parse(geojson).geometry.coordinates
              if (markerGeoJson[0] < -90 || markerGeoJson[0] > 90 || markerGeoJson[1] < -180 || markerGeoJson[1] > 180) {
                ctrl.deleteShape(locContainer.dataset.shapeId);
                shapeFieldContainer.querySelector(`[data-shape-id="${locContainer.dataset.shapeId}"]`).remove();
                valid = false;
              }
              if (valid) {
                ctrl.addMarker(markerGeoJson, "editEv", locContainer.dataset.shapeId);
                bounds.push(markerGeoJson);
              }
            } else if (objectShape === "LineString") {
              const lineGeoJson = JSON.parse(geojson).geometry.coordinates.map((coords) => {
                if (coords[0] < -90 || coords[0] > 90 || coords[1] < -180 || coords[1] > 180) {
                  ctrl.deleteShape(locContainer.dataset.shapeId);
                  shapeFieldContainer.querySelector(`[data-shape-id="${locContainer.dataset.shapeId}"]`).remove();
                  valid = false;
                }
                return [coords[0], coords[1]];
              })
              if (valid) {
                ctrl.addLine(lineGeoJson, "editEv", locContainer.dataset.shapeId);
                bounds.push(lineGeoJson);
              }
            } else if (objectShape === "Polygon") {
              const polygonGeoJson = JSON.parse(geojson).geometry.coordinates.map(
                (coord) => coord.map(
                  (coords) => {
                    if (coords[0] < -90 || coords[0] > 90 || coords[1] < -180 || coords[1] > 180) {
                      ctrl.deleteShape(locContainer.dataset.shapeId);
                      shapeFieldContainer.querySelector(`[data-shape-id="${locContainer.dataset.shapeId}"]`).remove();
                      valid = false;
                    }
                    return [coords[0], coords[1]];
                  })
              )
              if (valid) {
                ctrl.addPolygon(polygonGeoJson, "editEv", locContainer.dataset.shapeId);
                bounds.push(polygonGeoJson);
              }
            };
          } else {
            shapeFieldContainer.querySelector(`[data-shape-id="${locContainer.dataset.shapeId}"]`).remove();
          }
        }
      );

      if (bounds.length > 0) {
        const area = new L.LatLngBounds(bounds);
        ctrl.map.fitBounds(area);
      }
    }
  });
};
