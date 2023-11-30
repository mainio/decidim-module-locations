const centerShape = function (coords, shape) {
  let lat = null;
  let lng = null;
  let index = null;

  if (shape === "Line") {
    coords.map((coord) => {
      lat +=  coord.lat;
      lng += coord.lng;
      index += 1;

      return [lat, lng];
    });
  } else if (shape === "Polygon") {
    coords.map((coord) => {
      return coord.map((data) => {
        lat += data.lat;
        lng += data.lng;
        index += 1;

        return [lat, lng]
      })
    })
  };

  lat /= index
  lng /= index

  return {lat, lng};
};

export default centerShape;
