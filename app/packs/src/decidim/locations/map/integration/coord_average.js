import { getFirstValue } from "src/decidim/locations/map/integration/point_distance.js"

const coordAverage = function (shapeFieldContainer, wrapperEl) {
  const latArr = Array.from(shapeFieldContainer.querySelectorAll(".location-geojson"));
  const latitudes = [];
  latArr.forEach((val) => {
    const value = JSON.parse(val.value).geometry;
    latitudes.push(getFirstValue(value.coordinates, 0, value.type));
  });
  let latAvg = latitudes.reduce((pv, cv) => pv + cv, 0);
  latAvg /= latitudes.length;

  const lngArr = Array.from(shapeFieldContainer.querySelectorAll(".location-geojson"));
  const longitudes = [];
  lngArr.forEach((val) => {
    const value = JSON.parse(val.value).geometry;
    longitudes.push(getFirstValue(value.coordinates, 1, value.type));
  });
  let lngAvg = longitudes.reduce((pv, cv) => pv + cv, 0);
  lngAvg /= longitudes.length;

  if (isNaN(latAvg) && isNaN(lngAvg)) {
    latAvg = null;
    lngAvg = null;
  }

  wrapperEl.querySelector(".model-latitude").value = latAvg;
  wrapperEl.querySelector(".model-longitude").value = lngAvg;
};

export default coordAverage;
