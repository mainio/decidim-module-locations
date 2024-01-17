const addShapeField = function (shapeFieldContainer, shapeId) {
  const container = document.createElement("div");
  container.setAttribute("class", "shape-field");
  container.dataset.shapeId = shapeId;
  shapeFieldContainer.appendChild(container);
};

export default addShapeField;
