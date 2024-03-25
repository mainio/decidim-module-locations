const initializeSelectLocations = function (markers) {
  markers.getLayers().forEach((shape) => {
    shape.addEventListener("mouseover", () => {
      if (shape.options.shape === "Point") {
        shape._icon.style.filter = "hue-rotate(155deg)"
      } else {
        shape.setStyle({color: "#ff7b00"})
      }
    })

    shape.addEventListener("mouseout", () => {
      if (!shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(0deg)"
        } else {
          shape.setStyle({color: "#3388ff"})
        }
      } else if (shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(275deg)"
        } else {
          shape.setStyle({color: "#2bff00"})
        }
      }
    })

    shape.addEventListener("click", () => {
      if (!shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(275deg)"
        } else {
          shape.setStyle({color: "#2bff00"})
        }
        $(`input[value*="${$.escapeSelector(shape._tooltip._content)}"]`).click();
        shape.options.selected = true;
      } else if (shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(0deg)"
        } else {
          shape.setStyle({color: "#3388ff"})
        }
        $(`input[value*="${$.escapeSelector(shape._tooltip._content)}"]`).click();
        shape.options.selected = false;
      }
    })
  })
};


export default initializeSelectLocations;
