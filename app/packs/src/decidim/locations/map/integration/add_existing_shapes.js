const addExistingShapes = function (data, ctrl) {
  const objectShape = data.querySelector(".location-shape").value;
  const locationGeoJson = data.querySelector(".location-geojson").value;
  const geoJson = JSON.parse(locationGeoJson).geometry.coordinates;
  let shape = null;

  if (objectShape === "Point") {
    ctrl.addMarker(geoJson, "editEv", data.dataset.shapeId);
    shape = geoJson;
  } else if (objectShape === "LineString") {
    const lineGeoJson = geoJson.map((coords) => {
      return [coords[0], coords[1]];
    })
    ctrl.addLine(lineGeoJson, "editEv", data.dataset.shapeId);
    shape = lineGeoJson;
  } else if (objectShape === "Polygon") {
    const polygonGeoJson = geoJson.map(
      (coord) => coord.map(
        (coords) => {
          return [coords[0], coords[1]];
        }
      )
    )
    ctrl.addPolygon(polygonGeoJson, "editEv", data.dataset.shapeId);
    shape = polygonGeoJson;
  } else {
    const label = data.querySelector(".location-shape").value;

    ctrl.addCustom(geoJson, data.dataset.shapeId, label);
    shape = geoJson;
  }

  return shape;
};

export default addExistingShapes;
