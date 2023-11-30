const degreesToRadians = function (degrees) {
  return degrees * Math.PI / 180;
}

const getDistanceBetweenPoints = function (oldCoords, newCoords) {
  // The radius of the planet earth in meters
  let radius = 6378137;
  let dLat = degreesToRadians(newCoords[0] - oldCoords[0]);
  let dLng = degreesToRadians(newCoords[1] - oldCoords[1]);
  let op = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
         (Math.pow(Math.cos(degreesToRadians(oldCoords[0])), 2) *
          Math.pow(Math.sin(dLng / 2), 2));

  let cal = 2 * Math.atan2(Math.sqrt(op), Math.sqrt(1 - op));
  return radius * cal;
};

export default getDistanceBetweenPoints;
