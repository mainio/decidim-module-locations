import ModelLocMapController from "src/decidim/locations/map/controller/location";
import formIntegration from "src/decidim/locations/map/integration/forms";

const originalCreateMapController = window.Decidim.createMapController;

window.Decidim.createMapController = (mapId, config) => {
  if (config.type === "model_location") {
    return new ModelLocMapController(mapId, config);
  }

  return originalCreateMapController(mapId, config);
}

$(() => {
  formIntegration();
});

