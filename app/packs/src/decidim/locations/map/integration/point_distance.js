const degreesToRadians = function (degrees) {
  return degrees * Math.PI / 180;
}

const getFirstValue = function (value, position, objectShape) {
  if (objectShape === "Point") {
    return value[position];
  } else if (objectShape === "LineString") {
    return value[0][position]
  } else if (objectShape === "Polygon") {
    return value.map((array) =>
      array[0][position]
    );
  }

  return null;
}

const transformCoordinates = function (coordinates, objectShape) {
  if (objectShape === "Point") {
    return [coordinates.lat, coordinates.lng]
  } else if (objectShape === "LineString") {
    return coordinates.map((nest) =>
      [nest.lat, nest.lng]
    );
  } else if (objectShape === "Polygon") {
    return coordinates.map((array) =>
      array.map((nest) => [nest.lat, nest.lng])
    );
  }

  return null;
}

const getDistanceBetweenPoints = function (oldCoords, coordinates, objectShape) {
  const newCoords = transformCoordinates(coordinates, objectShape)

  // The radius of the planet earth in meters
  let radius = 6378137;
  let dLat = degreesToRadians(getFirstValue(newCoords, 0, objectShape) - getFirstValue(oldCoords, 0, objectShape));
  let dLng = degreesToRadians(getFirstValue(newCoords, 1, objectShape) - getFirstValue(oldCoords, 1, objectShape));
  let op = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
         (Math.pow(Math.cos(degreesToRadians(oldCoords[0])), 2) *
          Math.pow(Math.sin(dLng / 2), 2));

  let cal = 2 * Math.atan2(Math.sqrt(op), Math.sqrt(1 - op));
  return radius * cal;
};

export { getDistanceBetweenPoints, getFirstValue };
