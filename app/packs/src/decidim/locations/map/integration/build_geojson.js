const coordinatesToObject = function (coordinates, shape) {
  let value = JSON.parse(coordinates);
  if (shape === "Point") {
    value = [value.lat, value.lng];
  } else if (shape === "LineString") {
    value = value.map((coords) => {
      return [coords.lat, coords.lng];
    })
  } else if (shape === "Polygon") {
    value = value.map((array) => {
      return array.map((coords) => {
        return [coords.lat, coords.lng];
      })
    })
  }

  return value;
}

const buildGeoJson = function (coordinates, shape, address) {
  console.log(address)
  if (address) {
    return {
      "type": "Feature",
      "geometry": {
        "type": shape,
        "coordinates":
          coordinatesToObject(coordinates, shape)
      },
      "properties": {
        "address": address
      }
    }
  }

  return {
    "type": "Feature",
    "geometry": {
      "type": shape,
      "coordinates":
        coordinatesToObject(coordinates, shape)
    }
  }
};

export default buildGeoJson;
