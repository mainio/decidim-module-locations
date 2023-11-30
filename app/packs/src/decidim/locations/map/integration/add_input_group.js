import getDistanceBetweenPoints from "./point_distance.js";

const addInputGroup = function (markerFieldContainer, addressData, wrapperEl) {
  const markerId = addressData.markerId;
  const address = addressData.address;
  const shape = addressData.shape;
  const lat = addressData.position.lat;
  const lng = addressData.position.lng;
  const shapeCoordinates = JSON.stringify(addressData.shapeCoordinates);

  const markerField = markerFieldContainer.querySelector(`[data-marker-id="${markerId}"]`);
  if (markerField.hasChildNodes()) {
    const oldCoords = [markerField.querySelector(".location-latitude").value, markerField.querySelector(".location-longitude").value];
    const newCoords = [lat, lng];
    const markerRadius = getDistanceBetweenPoints(oldCoords, newCoords);

    if (markerRadius < 200) {
      markerField.querySelector(".location-latitude").value = lat;
      markerField.querySelector(".location-longitude").value = lng;
      markerField.querySelector(".location-geojson").value = shapeCoordinates;
    } else {
      markerField.querySelector(".location-address").value = address;
      markerField.querySelector(".location-shape").value = shape;
      markerField.querySelector(".location-latitude").value = lat;
      markerField.querySelector(".location-longitude").value = lng;
      markerField.querySelector(".location-geojson").value = shapeCoordinates;
    }
  } else {
    const template = wrapperEl.querySelector(`#model_input_template-${wrapperEl.querySelector("[data-decidim-map]").id}`);
    const clone = template.content.cloneNode(true);
    const addressInput = clone.querySelector(".location-address");
    const shapeInput = clone.querySelector(".location-shape");
    const latInput = clone.querySelector(".location-latitude");
    const lngInput = clone.querySelector(".location-longitude");
    const geoJsonInput = clone.querySelector(".location-geojson");

    addressInput.name = addressInput.name.replace("%index%", markerId)
    addressInput.value = address;
    shapeInput.name = shapeInput.name.replace("%index%", markerId);
    shapeInput.value = shape;
    latInput.name = latInput.name.replace("%index%", markerId);
    latInput.value = lat;
    lngInput.name = lngInput.name.replace("%index%", markerId);
    lngInput.value = lng;
    geoJsonInput.name = geoJsonInput.name.replace("%index%", markerId);
    geoJsonInput.value = shapeCoordinates;

    markerField.appendChild(clone);
  };
};

export default addInputGroup;
