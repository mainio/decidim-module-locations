const addMarkerField = function (markerFieldContainer, markerId) {
  const container = document.createElement("div");
  container.setAttribute("class", "marker-field");
  container.dataset.markerId = markerId;
  markerFieldContainer.appendChild(container);
};

export default addMarkerField;
