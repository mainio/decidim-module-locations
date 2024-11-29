const clearShapeFieldContainers = function (shapeFieldContainer) {
  shapeFieldContainer.querySelectorAll(".shape-field").forEach((shape) => shape.remove());
};

export default clearShapeFieldContainers;
