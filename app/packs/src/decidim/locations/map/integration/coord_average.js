const coordAverage = function (shapeFieldContainer, wrapperEl) {
  const latArr = Array.from(shapeFieldContainer.querySelectorAll(".location-latitude"));
  const latitudes = [];
  latArr.map((val) => latitudes.push(parseFloat(val.value)));
  let latAvg = latitudes.reduce((pv, cv) => pv + cv, 0);
  latAvg /= latitudes.length;

  const lngArr = Array.from(shapeFieldContainer.querySelectorAll(".location-longitude"));
  const longitudes = [];
  lngArr.map((val) => longitudes.push(parseFloat(val.value)));
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
