import { getDistanceBetweenPoints } from "src/decidim/locations/map/integration/point_distance.js";
import buildGeoJson from "src/decidim/locations/map/integration/build_geojson.js";

const addInputGroup = function (shapeFieldContainer, addressData, wrapperEl) {
  const shapeId = addressData.shapeId;
  const address = addressData.address;
  const objectShape = addressData.objectShape;
  const coordinates = JSON.stringify(addressData.coordinates);
  const shapeField = shapeFieldContainer.querySelector(`[data-shape-id="${shapeId}"]`);
  if (shapeField.hasChildNodes()) {
    const oldCoords = JSON.parse(shapeField.querySelector(".location-geojson").value).geometry.coordinates;
    const shapeRadius = getDistanceBetweenPoints(oldCoords, JSON.parse(coordinates), objectShape);

    if (shapeRadius < 200) {
      shapeField.querySelector(".location-geojson").value = JSON.stringify(buildGeoJson(coordinates, objectShape));
    } else {
      shapeField.querySelector(".location-address").value = address;
      shapeField.querySelector(".location-geojson").value = JSON.stringify(buildGeoJson(coordinates, objectShape));
    }
  } else {
    const template = wrapperEl.querySelector(`#model_input_template-${wrapperEl.querySelector(
      "[data-decidim-map]").id}`);
    const clone = template.content.cloneNode(true);
    const addressInput = clone.querySelector(".location-address");
    const geoJsonInput = clone.querySelector(".location-geojson");

    addressInput.name = addressInput.name.replace("%index%", shapeId)
    addressInput.value = address;
    geoJsonInput.name = geoJsonInput.name.replace("%index%", shapeId);
    geoJsonInput.value = JSON.stringify(buildGeoJson(coordinates, objectShape));

    shapeField.appendChild(clone);
  };
};

export default addInputGroup;
