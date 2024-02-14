import "src/decidim/vendor/jquery-tmpl"
import MapController from "src/decidim/map/controller"
import "leaflet.markercluster";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png"
import markerIcon from "leaflet/dist/images/marker-icon.png"
import markerShadow from "leaflet/dist/images/marker-shadow.png"

export default class MapMarkersController extends MapController {
  start() {
    this.markerClusters = null;

    if (Array.isArray(this.config.markers) && this.config.markers.length > 0) {
      this.addMarkers(this.config.markers);
    } else {
      this.map.fitWorld();
    }
  }

  addMarkers(markersData) {
    // eslint-disable-next-line
    delete L.Icon.Default.prototype._getIconUrl;

    L.Icon.Default.mergeOptions({
      iconRetinaUrl: markerIcon2x,
      iconUrl: markerIcon,
      shadowUrl: markerShadow
    });

    if (this.markerClusters === null) {
      this.markerClusters = new L.MarkerClusterGroup();
      this.map.addLayer(this.markerClusters);
    }

    // Pre-compiles the template
    $.template(
      this.config.popupTemplateId,
      $(`#${this.config.popupTemplateId}`).html()
    );

    const bounds = new L.LatLngBounds(
      markersData.map(
        (markerData) => [markerData.latitude, markerData.longitude]
      )
    );

    markersData.forEach((markerData) => {
      let shape = {}
      if (markerData.shape === "Point") {
        shape = L.marker([markerData.latitude, markerData.longitude], {
          title: markerData.title
        })
      } else if (markerData.shape === "LineString") {
        shape = L.polyline(JSON.parse(markerData.geojson).map((coords) => [coords.lat, coords.lng]), {
          title: markerData.title
        })
      } else if (markerData.shape === "Polygon") {
        shape = L.polygon(JSON.parse(markerData.geojson).map((coord) => coord.map((coords) => [coords.lat, coords.lng])), {
          title: markerData.title
        })
      }

      let node = document.createElement("div");

      $.tmpl(this.config.popupTemplateId, markerData).appendTo(node);
      shape.bindPopup(node, {
        maxwidth: 640,
        minWidth: 500,
        keepInView: true,
        className: "map-info"
      })

      this.markerClusters.addLayer(shape);
    });


    // Make sure there is enough space in the map for the padding to be
    // applied. Otherwise the map will automatically zoom out (test it on
    // mobile). Make sure there is at least the same amount of width and
    // height available on both sides + the padding (i.e. 4x padding in
    // total).
    const size = this.map.getSize();
    if (size.y >= 400 && size.x >= 400) {
      this.map.fitBounds(bounds, { padding: [100, 100] });
    } else if (size.y >= 120 && size.x >= 120) {
      this.map.fitBounds(bounds, { padding: [30, 30] });
    } else {
      this.map.fitBounds(bounds);
    }
  }

  clearMarkers() {
    this.map.removeLayer(this.markerClusters);
    this.markerClusters = new L.MarkerClusterGroup();
    this.map.addLayer(this.markerClusters);
  }
}
