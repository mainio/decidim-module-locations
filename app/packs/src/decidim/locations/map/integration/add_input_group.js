import getDistanceBetweenPoints from "./point_distance.js";
import buildGeoJson from "./build_geojson.js";

const addInputGroup = function (shapeFieldContainer, addressData, wrapperEl) {
  const parentNodeId = wrapperEl.parentNode.id;
  const shapeId = addressData.shapeId;
  const address = addressData.address;
  const objectShape = addressData.objectShape;
  const lat = addressData.position.lat;
  const lng = addressData.position.lng;
  const coordinates = JSON.stringify(addressData.coordinates);
  const shapeField = shapeFieldContainer.querySelector(`[data-shape-id="${shapeId}"]`);

  if (parentNodeId === "answer-option-map-selector") {
    const currentGeo = document.querySelector("button.location-selector").parentNode.querySelector("label > textarea");

    currentGeo.value = JSON.stringify(buildGeoJson(coordinates, objectShape, address));
  } else {
    if (shapeField.hasChildNodes()) {
      const oldCoords = [shapeField.querySelector(".location-latitude").value,
        shapeField.querySelector(".location-longitude").value];
      const newCoords = [lat, lng];
      const shapeRadius = getDistanceBetweenPoints(oldCoords, newCoords);

      if (shapeRadius < 200) {
        shapeField.querySelector(".location-latitude").value = lat;
        shapeField.querySelector(".location-longitude").value = lng;
        shapeField.querySelector(".location-geojson").value = JSON.stringify(buildGeoJson(coordinates, objectShape));
      } else {
        shapeField.querySelector(".location-address").value = address;
        shapeField.querySelector(".location-shape").value = objectShape;
        shapeField.querySelector(".location-latitude").value = lat;
        shapeField.querySelector(".location-longitude").value = lng;
        shapeField.querySelector(".location-geojson").value = JSON.stringify(buildGeoJson(coordinates, objectShape));
      }
    } else {
      const template = wrapperEl.querySelector(`#model_input_template-${wrapperEl.querySelector(
        "[data-decidim-map]").id}`);
      const clone = template.content.cloneNode(true);
      const addressInput = clone.querySelector(".location-address");
      const shapeInput = clone.querySelector(".location-shape");
      const latInput = clone.querySelector(".location-latitude");
      const lngInput = clone.querySelector(".location-longitude");
      const geoJsonInput = clone.querySelector(".location-geojson");

      addressInput.name = addressInput.name.replace("%index%", shapeId)
      addressInput.value = address;
      shapeInput.name = shapeInput.name.replace("%index%", shapeId);
      shapeInput.value = objectShape;
      latInput.name = latInput.name.replace("%index%", shapeId);
      latInput.value = lat;
      lngInput.name = lngInput.name.replace("%index%", shapeId);
      lngInput.value = lng;
      geoJsonInput.name = geoJsonInput.name.replace("%index%", shapeId);
      geoJsonInput.value = JSON.stringify(buildGeoJson(coordinates, objectShape));

      shapeField.appendChild(clone);
    };
  };
};

export default addInputGroup;
