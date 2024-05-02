const initializeSelectLocations = function (markers) {
  markers.getLayers().forEach((shape) => {
    shape.addEventListener("mouseover", () => {
      if (shape.options.shape === "Point") {
        shape._icon.style.filter = "hue-rotate(155deg)"
        shape._tooltip._container.style.backgroundColor = "#ff7b00"
      } else {
        shape.setStyle({color: "#ff7b00"})
        shape._tooltip._container.style.backgroundColor = "#ff7b00"
      }
    })

    shape.addEventListener("mouseout", () => {
      if (!shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(0deg)"
          shape._tooltip._container.style.backgroundColor = "white"
        } else {
          shape.setStyle({color: "#3388ff"})
          shape._tooltip._container.style.backgroundColor = "white"
        }
      } else if (shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(275deg)"
          shape._tooltip._container.style.backgroundColor = "#2bff00"
        } else {
          shape.setStyle({color: "#2bff00"})
          shape._tooltip._container.style.backgroundColor = "#2bff00"
        }
      }
    })

    shape.addEventListener("click", () => {
      if (!shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(275deg)"
          shape._tooltip._container.style.backgroundColor = "#2bff00"
        } else {
          shape.setStyle({color: "#2bff00"})
          shape._tooltip._container.style.backgroundColor = "#2bff00"
        }
        $(`#answer-option-${shape.options.answerOption}`).find('input[type="checkbox"]').click();
        shape.options.selected = true;
      } else if (shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(0deg)"
          shape._tooltip._container.style.backgroundColor = "white"
        } else {
          shape.setStyle({color: "#3388ff"})
          shape._tooltip._container.style.backgroundColor = "white"
        }
        $(`#answer-option-${shape.options.answerOption}`).find('input[type="checkbox"]').click();
        shape.options.selected = false;
      }
    })
  })
};


export default initializeSelectLocations;
