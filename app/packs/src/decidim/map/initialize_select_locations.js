const initializeSelectLocations = function (markers) {
  markers.getLayers().forEach((shape) => {
    const $shapeInput = $(`#answer-option-${shape.options.answerOption} input[type="checkbox"]`)

    if ($shapeInput.prop("checked")) {
      if (shape.options.shape === "Point") {
        if (shape._icon) {
          shape._icon.style.filter = "hue-rotate(275deg)"
        }
      } else {
        shape.setStyle({color: "#2bff00"})
      }
      shape.options.selected = true;
    }
    shape.addEventListener("mouseover", () => {
      if (shape.options.shape === "Point") {
        shape._icon.style.filter = "hue-rotate(155deg)"
      } else {
        shape.setStyle({color: "#ff7b00"})
      }
      shape._tooltip._container.style.backgroundColor = "#ff7b00"
    })

    shape.addEventListener("mouseout", () => {
      if (!shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(0deg)"
        } else {
          shape.setStyle({color: "#3388ff"})
        }
        shape._tooltip._container.style.backgroundColor = "white"
      } else if (shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(275deg)"
        } else {
          shape.setStyle({color: "#2bff00"})
        }
        shape._tooltip._container.style.backgroundColor = "#2bff00"
      }
    })

    shape.addEventListener("click", () => {
      if (!shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(275deg)"
        } else {
          shape.setStyle({color: "#2bff00"})
        }
        shape._tooltip._container.style.backgroundColor = "#2bff00"
        $(`#answer-option-${shape.options.answerOption}`).find('input[type="checkbox"]').click();
        shape.options.selected = true;
      } else if (shape.options.selected) {
        if (shape.options.shape === "Point") {
          shape._icon.style.filter = "hue-rotate(0deg)"
        } else {
          shape.setStyle({color: "#3388ff"})
        }
        shape._tooltip._container.style.backgroundColor = "white"
        $(`#answer-option-${shape.options.answerOption}`).find('input[type="checkbox"]').click();
        shape.options.selected = false;
      }
    })
  })
};


export default initializeSelectLocations;
