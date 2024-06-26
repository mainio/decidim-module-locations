import "src/decidim/vendor/jquery-tmpl"
import MapController from "src/decidim/map/controller"
import "leaflet.markercluster";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png"
import markerIcon from "leaflet/dist/images/marker-icon.png"
import markerShadow from "leaflet/dist/images/marker-shadow.png"
import initializeSelectLocations from "src/decidim/map/initialize_select_locations"

export default class MapMarkersController extends MapController {
  start() {
    this.markerClusters = null;

    if (Array.isArray(this.config.markers) && this.config.markers.length > 0) {
      this.addMarkers(this.config.markers);
    } else {
      this.map.fitWorld();
    }

    if (this.selectLocation()) {
      initializeSelectLocations(this.markerClusters);
    }
  }

  selectLocation() {
    const decidimMap = this.map._container.getAttribute("data-decidim-map");
    return JSON.parse(decidimMap).selectLocation;
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
        (markerData) => {
          if (markerData.geojson) {
            return markerData.geojson.geometry.coordinates
          }

          return [markerData.latitude, markerData.longitude]
        }
      )
    );

    markersData.forEach((markerData) => {
      let shape = {}
      if (markerData.location && markerData.geojson) {
        const coordinates = markerData.geojson.geometry.coordinates;
        const location = markerData.location;
        const objectShape = markerData.geojson.geometry.type;

        if (objectShape === "Point") {
          shape = L.marker(
            coordinates,
            {selected: false,
              location: location.en,
              geojson: JSON.stringify(markerData.geojson),
              shape: objectShape,
              answerOption: markerData.answer_option})
        } else if (objectShape === "LineString") {
          shape = L.polyline(
            coordinates,
            {selected: false,
              location: location.en,
              geojson: JSON.stringify(markerData.geojson),
              shape: objectShape,
              answerOption: markerData.answer_option})
        } else if (objectShape === "Polygon") {
          shape = L.polygon(
            coordinates,
            {selected: false,
              location: location.en,
              geojson: JSON.stringify(markerData.geojson),
              shape: objectShape,
              answerOption: markerData.answer_option})
        }

        shape.bindTooltip(location.en, {direction: markerData.tooltip_direction, permanent: true, interactive: true});

        this.markerClusters.addLayer(shape);
      } else if (markerData.geojson) {
        const coordinates = markerData.geojson.geometry.coordinates;

        if (markerData.shape === "Point") {
          shape = L.marker(coordinates,
            {
              title: markerData.title
            }
          )
        } else if (markerData.shape === "LineString") {
          shape = L.polyline(coordinates,
            {
              title: markerData.title
            }
          )
        } else if (markerData.shape === "Polygon") {
          shape = L.polygon(coordinates,
            {
              title: markerData.title
            }
          )
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
      } else {
        let marker = new L.Marker([markerData.latitude, markerData.longitude], {
          icon: this.createIcon(),
          keyboard: true,
          title: markerData.title
        });

        let node = document.createElement("div");

        $.tmpl(this.config.popupTemplateId, markerData).appendTo(node);
        marker.bindPopup(node, {
          maxwidth: 640,
          minWidth: 500,
          keepInView: true,
          className: "map-info"
        }).openPopup();

        this.markerClusters.addLayer(marker);
      }
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

  refreshMarkers() {
    const tooltips = document.getElementsByClassName("leaflet-tooltip");

    // Hiding tooltips for now to fix multiple page map questions. Where tooltips offset from the shapes.
    // unbindTooltip etc. methods don't work for some reason, probably
    // because tooltips are permanent.
    Array.from(tooltips).forEach((tooltip) => {
      tooltip.style.display = "none";
    })

    this.markerClusters.eachLayer((marker) => {

      marker.bindTooltip(marker.options.location, {direction: marker.tooltip_direction, permanent: true, interactive: true});
    })
  }
}
