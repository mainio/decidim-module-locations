import "leaflet"
import "src/decidim/vendor/leaflet-tilelayer-here"
import "src/decidim/geoman/leaflet-geoman.min.js";

/**
 * NOTE:
 * This has to load before decidim/map in order for it to apply correctly when
 * the map is initialized. The document.ready handler set by this script has to
 * be registered before decidim/map registers its own.
 */
$(() => {
  $("[data-decidim-map]").on("configure.decidim", (_ev, map, mapConfig) => {
    L.tileLayer.here(mapConfig.tileLayer).addTo(map);
  });
});
