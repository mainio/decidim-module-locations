const centerShape = function (coords, objectShape) {
  let lat = null;
  let lng = null;
  let index = null;

  if (objectShape === "Line") {
    coords.map((coord) => {
      lat +=  coord.lat;
      lng += coord.lng;
      index += 1;

      return [lat, lng];
    });
  } else if (objectShape === "Polygon") {
    coords.map((coord) => {
      return coord.map((data) => {
        lat += data.lat;
        lng += data.lng;
        index += 1;

        return [lat, lng]
      })
    })
  } else if (objectShape === "Marker") {
    return coords;
  };

  lat /= index
  lng /= index

  return {lat, lng};
};

export default centerShape;
