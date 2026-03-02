import "leaflet"
import "leaflet-tilelayer-here"
import "src/decidim/geoman/leaflet-geoman-2.18.3.js";

/**
 * NOTE:
 * This has to load before decidim/map in order for it to apply correctly when
 * the map is initialized. The document.ready handler set by this script has to
 * be registered before decidim/map registers its own.
 */
$(() => {
  $("[data-decidim-map]").on("configure.decidim", (_ev, map, mapConfig) => {
    console.log("HOG")
    L.tileLayer.here(mapConfig.tileLayer).addTo(map);
  });
});
