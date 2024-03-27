import MapController from "src/decidim/map/controller";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png"
import markerIcon from "leaflet/dist/images/marker-icon.png"
import markerShadow from "leaflet/dist/images/marker-shadow.png"

export default class ModelLocMapController extends MapController {
  start() {
    this.initializeMap();
    this.shapes = {};
  }

  initializeMap() {
    // eslint-disable-next-line
    delete L.Icon.Default.prototype._getIconUrl;

    L.Icon.Default.mergeOptions({
      iconRetinaUrl: markerIcon2x,
      iconUrl: markerIcon,
      shadowUrl: markerShadow
    });

    const mapEl = this.map._container;
    // Position the center of the map
    const lat = mapEl.dataset.lat;
    const lng = mapEl.dataset.lng;
    const selectLocation = mapEl.dataset.selectLocation;

    let defaultLat = 0;
    let defaultLng = 0;
    let zoom = 0;

    if (selectLocation === "false" && (lat !== defaultLat.toFixed(1) || lng !== defaultLng.toFixed(1))) {
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
      {
        ignoreShapes: ["Circle", "Rectangle"]
      }
    );
  }

  addLocation(geoJson) {
    const objectShape = JSON.parse(geoJson).geometry.type;
    const coordinates = JSON.parse(geoJson).geometry.coordinates;

    if (objectShape === "Point") {
      this.addMarker(coordinates, "editEv");
    } else if (objectShape === "LineString") {
      this.addLine(coordinates, "editEv");
    } else if (objectShape === "Polygon") {
      this.addPolygon(coordinates, "editEv");
    }

    const bounds = new L.LatLngBounds([coordinates]);

    this.map.fitBounds(bounds);
  }

  clearShapes() {
    Object.keys(this.shapes).forEach((shapeIdKey) => {
      this.deleteShape(shapeIdKey)
    })
  }

  deleteShape(shapeId) {
    const shape = this.shapes[shapeId];
    if (!shape) {
      return;
    }

    Reflect.deleteProperty(this.shapes, shapeId);
    this.map.removeLayer(shape);
  }

  addMarker(data, ev, id) {
    // Add a marker to the map
    let shapeId = null;
    if (ev === "editEv") {
      shapeId = id;
    } else {
      shapeId = Math.random().toString(36).slice(2, 9);
    }
    const marker = L.marker(data, {
      draggable: true,
      id: shapeId
    })
    this.shapes[shapeId] = marker;
    marker.addTo(this.map);
    this.triggerEvent("shapeadd", [marker, ev]);

    return shapeId;
  }

  addLine(data, ev, id) {
    // Add a line to the map
    let shapeId = null;
    if (ev === "editEv") {
      shapeId = id;
    } else {
      shapeId = Math.random().toString(36).slice(2, 9);
    }
    const line = L.polyline(data,
      {
        draggable: true,
        id: shapeId
      })
    this.shapes[shapeId] = line;
    line.addTo(this.map);
    this.triggerEvent("shapeadd", [line, ev]);
    return shapeId;
  }

  addPolygon(data, ev, id) {
    // Add a polygon to the map
    let shapeId = null;
    if (ev === "editEv") {
      shapeId = id;
    } else {
      shapeId = Math.random().toString(36).slice(2, 9);
    }
    const polygon = L.polygon(data,
      {
        draggable: true,
        id: shapeId
      })
    this.shapes[shapeId] = polygon;
    polygon.addTo(this.map);
    this.triggerEvent("shapeadd", [polygon, ev]);
    return shapeId;
  }

  bindFetchPopup(shapeId) {
    const shape = this.shapes[shapeId];
    if (!shape) {
      return;
    }

    shape.bindPopup("Fetching address for this shape").openPopup();
  }

  bindNoDataPopup(shapeId) {
    const shape = this.shapes[shapeId];
    if (!shape) {
      return;
    }

    shape.bindPopup("No address found for this shape").openPopup();
  }

  unbindPopup(shapeId) {
    const shape = this.shapes[shapeId];
    shape.closePopup();
    shape.unbindPopup();
  }

  setView(coordinates) {
    this.map.setView(coordinates);
  }
}
