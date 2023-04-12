import * as L from "leaflet";
import MapController from "src/decidim/map/controller"
import "src/decidim/vendor/leaflet-tilelayer-here"

export default class ModelLocMapController extends MapController {
  start() {
    this.positionMap();
    this.addListeners();
    this.placeMarkers = false;
    this.markers = {};
  }

  positionMap() {
    // Position the center of the map
    const mapCenter = [60.150428, 24.887953];
    const zoom = 14;
    this.map.setView(mapCenter, zoom);
  }

  addListeners() {
    // Add listener for the map
    this.map.on("click", (ev) => {
      if (!this.placeMarkers) {
        return;
      }

      this.addMarker(ev, "clickEv");
    })
  }

  clearMarkers() {
    Object.keys(this.markers).forEach((markerIdKey) => {
      this.deleteMarker(markerIdKey)
    })
  }

  enablePlaceMarkers() {
    this.map.doubleClickZoom.disable();
    this.placeMarkers = true;
  }

  disablePlaceMarkers() {
    this.map.doubleClickZoom.enable();
    this.placeMarkers = false;
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
        icon: this.createIcon(),
        draggable: true,
        id: markerId
      })
    } else {
      marker = L.marker(data, {
        icon: this.createIcon(),
        draggable: true,
        id: markerId
      })
    }
    this.markers[markerId] = marker;
    this.triggerEvent("markeradd", [marker, ev]);
    marker.addTo(this.map);

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
