const initializeSelectLocations = function (markers) {
  markers.getLayers().forEach((shape) => {
    shape.addEventListener("mouseover", () => {
      shape.setStyle({color: "#ff7b00"})
    })

    shape.addEventListener("mouseout", () => {
      if (!shape.options.selected) {
        shape.setStyle({color: "#3388ff"})
      } else if (shape.options.selected) {
        shape.setStyle({color: "#2bff00"})
      }
    })

    shape.addEventListener("click", () => {
      shape.setStyle({color: "#2bff00"})
      if (!shape.options.selected) {
        shape.options.selected = true;
        shape.setStyle({color: "#2bff00"})
        document.querySelector(`input[value="${CSS.escape(shape.options.geojson)}"]`).click();
      } else if (shape.options.selected) {
        shape.options.selected = false;
        shape.setStyle({color: "#3388ff"})
        document.querySelector(`input[value="${CSS.escape(shape.options.geojson)}"]`).click();
      }
    })
  })
};


export default initializeSelectLocations;
