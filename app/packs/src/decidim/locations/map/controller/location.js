import MapController from "src/decidim/map/controller";

export default class ModelLocMapController extends MapController {
  start() {
    this.initializeMap();
    this.placeMarkers = false;
    this.markers = {};
  }

  initializeMap() {
    delete L.Icon.Default.prototype._getIconUrl;

    L.Icon.Default.mergeOptions({
      iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
      iconUrl: require('leaflet/dist/images/marker-icon.png'),
      shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
    });

    const mapEl = this.map._container;
    // Position the center of the map
    const lat = mapEl.dataset.lat;
    const lng = mapEl.dataset.lng;

    let defaultLat = 0;
    let defaultLng = 0;
    let zoom = 0;

    if (lat !== defaultLat.toFixed(1) || lng !== defaultLng.toFixed(1)) {
      defaultLat = lat;
      defaultLng = lng;
      zoom = 14;
    }

    this.map.setView([defaultLat, defaultLng], zoom);

    L.PM.reInitLayer(this.map)

    this.map.pm.addControls({
      position: "topleft",
      drawCircleMarker: false,
      drawRectangle: false,
      drawCircle: false,
      drawText: false,
      cutPolygon: false,
      rotateMode: false,
      editMode: false
    });

    this.map.pm.setPathOptions(
      { color: "orange" },
      {
        ignoreShapes: ["Polyline", "Rectangle"]
      }
    );
  }

  clearMarkers() {
    Object.keys(this.markers).forEach((markerIdKey) => {
      this.deleteMarker(markerIdKey)
    })
  }

  deleteMarker(markerId) {
    const marker = this.markers[markerId];
    if (!marker) {
      return;
    }

    Reflect.deleteProperty(this.markers, markerId);
    this.map.removeLayer(marker);
  }

  addMarker(data, ev, id) {
    // Add a marker to the map
    let markerId = null;
    if (ev === "editEv") {
      markerId = id;
    } else {
      markerId = Math.random().toString(36).slice(2, 9);
    }
    let marker = null;
    if (typeof data === "object" && data !== null && !Array.isArray(data)) {
      marker = L.marker(data.latlng, {
        draggable: true,
        id: markerId
      })
    } else {
      marker = L.marker(data, {
        draggable: true,
        id: markerId
      })
    }
    this.markers[markerId] = marker;
    marker.addTo(this.map);
    this.triggerEvent("markeradd", [marker, ev]);

    return markerId;
  }

  bindPopUp(markerId) {
    const marker = this.markers[markerId];
    if (!marker) {
      return;
    }

    marker.bindPopup("Fetching address for this marker");
  }

  unbindPopUp(markerId) {
    const marker = this.markers[markerId];
    marker.closePopup();
    marker.unbindPopup();
  }

  setView(coordinates) {
    this.map.setView(coordinates);
  }
}
