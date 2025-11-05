/* eslint-disable max-lines */

import MapController from "src/decidim/map/controller";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";
import icon from "src/decidim/icon";

// See: https://geoman.io/docs/leaflet/customize/language
const geomanSupportedLanguages = [
  "cz", "da", "de", "el", "en", "es", "fa", "fi", "fr", "hu", "id", "it", "ja",
  "ko", "ky", "nl", "no", "pl", "pt_br", "pt_pt", "ro", "ru", "sv", "tr", "ua",
  "zh", "zh_tw"
];

const leafletTranslations = {
  en: {
    zoomIn: "Zoom in",
    zoomOut: "Zoom out",
    clearAll: "Clear everything",
    clearAllConfirm: "Are you sure you want to clear everything from the map?",
    confirmYes: "Yes",
    confirmNo: "No",
    fetchingAddress: "Fetching address for this marking...",
    noAddressFound: "No address found for this marking.",
    placeMarkerTip: "Place the markers by clicking the map.",
    lockOrUnlock: "Lock or unlock the map position."
  },
  fi: {
    zoomIn: "Lähennä",
    zoomOut: "Loitonna",
    clearAll: "Poista kaikki",
    clearAllConfirm: "Haluatko varmasti poistaa kartalta kaiken?",
    confirmYes: "Kyllä",
    confirmNo: "En",
    fetchingAddress: "Etsitään osoitetta tälle merkinnälle...",
    noAddressFound: "Merkinnälle ei löytynyt osoitetta.",
    placeMarkerTip: "Aseta merkkejä kartalle klikkaamalla.",
    lockOrUnlock: "Lukitse tai vapauta kartan sijainti."
  },
  sv: {
    zoomIn: "Zooma in",
    zoomOut: "Zooma ut",
    clearAll: "Rensa allt",
    clearAllConfirm: "Är du säker på att du vill ta bort allt från kartan?",
    confirmYes: "Ja",
    confirmNo: "Nej",
    fetchingAddress: "Hämtar adress för denna markering...",
    noAddressFound: "Ingen adress hittades för denna märkning.",
    placeMarkerTip: "Placera markörerna genom att klicka på kartan.",
    lockOrUnlock: "Lås eller lås upp kartpositionen"
  }
}

const getSupportedLanguage = (availableLanguages) => {
  let lang = document.documentElement.getAttribute("lang");
  if (!lang) {
    return null;
  }

  lang = lang.toLocaleLowerCase().replace("-", "_");
  if (availableLanguages.includes(lang)) {
    return lang;
  }
  if (lang.indexOf("_") < 0) {
    return null;
  }

  lang = lang.split("_")[0];
  if (availableLanguages.includes(lang)) {
    return lang;
  }

  return null;
}

const getGeomanLanguage = () => getSupportedLanguage(geomanSupportedLanguages);

const getLeafletLanguage = () => getSupportedLanguage(Object.keys(leafletTranslations)) || "en";

const translate = (lang, key) => {
  if (!leafletTranslations[lang]) {
    if (lang !== "en") {
      return translate("en", key);
    }
    return key;
  }

  return leafletTranslations[lang][key] || key;
};

/**
 * Translates the Leaflet elements that do not currently support i18n.
 *
 * @param {L.map} map The Leaflet map
 * @param {String} lang The language.
 * @returns {void}
 */
const translateMap = (map, lang) => {
  if (map.zoomControl) {
    const zoomContainer = map.zoomControl.getContainer();
    const controls = {
      zoomIn: zoomContainer.querySelector(".leaflet-control-zoom-in"),
      zoomOut: zoomContainer.querySelector(".leaflet-control-zoom-out")
    };
    for (let key of Object.keys(controls)) {
      const el = controls[key];
      const str = translate(lang, key);
      el.setAttribute("title", str);
      el.setAttribute("aria-label", str);
    }
  }
};

/**
 * Checks if the device has a "fine" pointer (such as a mouse) and can therefore
 * display the "cursor marker", i.e. the marker that follows the mouse
 * movements.
 *
 * @returns {Boolean} A boolean indicating whether the device has a pointer
 *   device with a visible cursor.
 */
const deviceHasFinePointer = () => {
  return window.matchMedia("(pointer:fine)").matches;
};

/**
 * Injects the special styles to the DOM.
 *
 * @returns {void}
 */
let injectStyles = () => {
  const style = document.createElement("style");
  style.innerHTML = `
    .leaflet-confirm-pane {
      position: absolute;
      display: none;
      z-index: 2000;
      top: 0;
      bottom: 0;
      left: 0;
      right: 0;
      background: #000000b3;
    }
    .leaflet-confirm-pane-display {
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .leaflet-confirm-pane-wrapper {
      display: flex;
      flex-direction: column;
      margin: 1rem;
      gap: 1rem;
    }
    .leaflet-confirm-pane-content {
      font-weight: bold;
      color: #fff;
      text-align: center;
    }
    .leaflet-confirm-pane-actions {
      display: flex;
      justify-content: center;
      gap: 1rem;
    }
    .leaflet-tooltip-stickynote::before {
      display: none;
    }
    .leaflet-control-icon-svg {
      display: block;
    }
    .leaflet-control-icon-svg > svg {
      pointer-events: none;
    }
    .leaflet-control-icon-svg,
    .leaflet-control-icon-svg > svg {
      width: 100%;
      height: 100%;
    }
  `;

  document.head.appendChild(style);

  // Replace the method after the injection is done
  injectStyles = () => {};
};

/**
 * Creates the confirm pane for the map and displays it with the given options.
 * Only creates the pane if it does not already exist.
 *
 * @param {L.map} map The Leaflet map
 * @param {Object} options The options for the confirm pane
 * @returns {void}
 */
const createLeafletConfirm = (map, options) => {
  let confirmPane = map.getPane("confirmPane");
  if (!map._confirmPane) {
    confirmPane = map.createPane("confirmPane", map._container);

    const confirmWrapper = L.DomUtil.create("div", "leaflet-confirm-pane-wrapper");
    const confirmContent = L.DomUtil.create("div", "leaflet-confirm-pane-content h4");
    const buttonWrapper = L.DomUtil.create("div", "leaflet-confirm-pane-actions");

    confirmContent.setAttribute("tabindex", "-1");

    const confirmButtons = {
      no: L.DomUtil.create("button", "leaflet-confirm-pane-button button button__sm button__transparent-secondary"),
      yes: L.DomUtil.create("button", "leaflet-confirm-pane-button button button__sm button__secondary")
    };

    const leafletLang = getLeafletLanguage();
    for (let action of Object.keys(confirmButtons)) {
      let btn = confirmButtons[action];
      btn.setAttribute("type", "button");
      btn.setAttribute("data-leaflet-confirm-action", action);
      btn.innerText = translate(leafletLang, `confirm${action.charAt(0).toUpperCase()}${action.slice(1)}`)
      buttonWrapper.appendChild(btn);
    }

    confirmButtons.no.addEventListener("click", (ev) => {
      ev.preventDefault();
      confirmPane.classList.remove("leaflet-confirm-pane-display");
    });

    confirmWrapper.appendChild(confirmContent);
    confirmWrapper.appendChild(buttonWrapper);
    confirmPane.appendChild(confirmWrapper);
  }

  // Replace the "yes" button with a new element in order to remove all previous
  // event listeners.
  const oldButton = confirmPane.querySelector("button[data-leaflet-confirm-action='yes']");
  const confirmButton = oldButton.cloneNode(true);
  oldButton.replaceWith(confirmButton);
  confirmButton.addEventListener("click", (ev) => {
    ev.preventDefault();
    confirmPane.classList.remove("leaflet-confirm-pane-display");

    if (typeof options.callback === "function") {
      options.callback();
    }
  });

  confirmPane.querySelector(".leaflet-confirm-pane-content").innerText = options.questionText;
  confirmPane.classList.add("leaflet-confirm-pane-display");

  // Place the tab focus inside the confirm content
  confirmPane.querySelector(".leaflet-confirm-pane-content").focus();
};

/**
 * This class handles the single controls within a control group.
 */
class CustomControl {
  constructor(container, options) {
    this.container = container;
    this.options = options;
    this.buttonContainer = L.DomUtil.create("div", "button-container", this.container);

    const button = L.DomUtil.create("a", "leaflet-buttons-control-button", this.buttonContainer);
    button.innerHTML = `<span class="leaflet-control-icon-svg">${icon(options.icon)}</span>`;
    button.href = "#";
    button.title = options.title;

    button.setAttribute("role", "button");
    button.setAttribute("aria-label", button.title);

    L.DomEvent.disableClickPropagation(button);
    L.DomEvent.on(button, "click", L.DomEvent.stop);
    L.DomEvent.on(button, "click", this._handleClick, this);

    this.button = button;
  }

  getButton() {
    return this.button;
  }

  _handleClick() {
    if (this.options.togglable) {
      this.buttonContainer.classList.toggle("active");
      if (typeof this.options.onToggle === "function") {
        this.options.onToggle(this.buttonContainer.classList.contains("active"));
      }
    }
  }
}

let CustomControlGroup = null;

/**
 * Creates a custom control group to hold custom buttons for the map.
 *
 * @param {Object} options Options for the control group.
 * @returns {CustomControlGroup} The group to hold the custom controls.
 */
const createMapControlGroup = (options) => {
  if (!CustomControlGroup) {
    CustomControlGroup = L.Control.extend({
      initialize(groupOptions) {
        Reflect.apply(L.Control.prototype.initialize, this, [groupOptions])

        this.controlOptions = [];
      },

      onAdd() {
        const groupName = `leaflet-control-${this.options.groupName}`;
        const container = L.DomUtil.create("div", `leaflet-pm-toolbar ${groupName} leaflet-bar leaflet-control`);

        for (let opts of this.controlOptions) {
          const ctrl = new CustomControl(container, opts);
          L.DomEvent.on(ctrl.getButton(), "click", this._refocusOnMap, this);
        }

        return container;
      },

      addControl(ctrlOpts) {
        this.controlOptions.push(ctrlOpts);
      }
    });
  }

  return new CustomControlGroup(options);
};

export default class ModelLocMapController extends MapController {
  start() {
    this.initializeMap();
    this.shapes = {};
    this.autoAdd = false;
  }

  initializeMap() {
    injectStyles();

    Reflect.deleteProperty(L.Icon.Default.prototype, "_getIconUrl");

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
    const zoom = mapEl.dataset.zoom;

    let defaultLat = 0;
    let defaultLng = 0;
    let defaultZoom = 0;

    if (selectLocation === "false" && (lat !== defaultLat.toFixed(1) || lng !== defaultLng.toFixed(1))) {
      defaultLat = lat;
      defaultLng = lng;
      defaultZoom = zoom;
    }

    this.map.setView([defaultLat, defaultLng], defaultZoom);
    L.PM.reInitLayer(this.map);

    const geomanLang = getGeomanLanguage();
    if (geomanLang) {
      this.map.pm.setLang(geomanLang);
    }

    const leafletLang = getLeafletLanguage();
    if (leafletLang) {
      translateMap(this.map, leafletLang);
    }

    // Replace the `removalMode` button with a custom implementation to add the
    // clear all functionality to it.
    const removalModeTitle = this.map.pm.Toolbar.buttons.removalMode._button.title;
    this.map.pm.Toolbar.buttons.removalMode.remove();
    Reflect.deleteProperty(this.map.pm.Toolbar.buttons, "removalMode");
    this.map.pm.Toolbar.createCustomControl({
      name: "removalMode",
      title: removalModeTitle,
      className: "leaflet-pm-icon-delete",
      doToggle: true,
      toggleStatus: false,
      disableOtherButtons: true,
      tool: "edit",
      actions: [
        "finishMode",
        {
          name: "clear",
          text: translate(leafletLang, "clearAll"),
          onClick: () => {
            createLeafletConfirm(this.map, {
              questionText: translate(leafletLang, "clearAllConfirm"),
              callback: () => {
                this.map.pm.disableGlobalRemovalMode();
                this.map.pm.Toolbar.toggleButton("removalMode", this.map.pm.globalRemovalModeEnabled());

                this.clearShapes();
              }
            });
          }
        }
      ],
      onClick: () => {},
      afterClick: () => {
        this.map.pm.toggleGlobalRemovalMode();
      }
    });
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

    this._addCustomControls();
    this._setupTouchScreenTips();
  }

  _addCustomControls() {
    if (!deviceHasFinePointer()) {
      const group = createMapControlGroup({
        groupName: "touch-utilities",
        position: "topright"
      });

      group.addControl({
        title: translate(getLeafletLanguage(), "lockOrUnlock"),
        icon: "lock-line",
        position: "topright",
        togglable: true,
        onToggle: (enabled) => {
          if (enabled) {
            this.map.dragging.disable();
          } else {
            this.map.dragging.enable();
          }
        }
      });

      group.addTo(this.map);
    }
  }

  /**
   * Fix the weird behavior for touch screens (i.e. screens that do not have a
   * "fine" pointer) for placing the markers.
   *
   * On touch devices without a "fine" pointer (i.e. a mouse pointer), the
   * experience is otherwise quite confusing to point out to the user what they
   * should be doing. This is used to modify the behavior of the marker draw
   * mode where the user places points on the map.
   *
   * @returns {void}
   */
  _setupTouchScreenTips() {
    let markerHintTip = null;
    const updateHintPosition = () => {
      if (!markerHintTip) {
        return;
      }

      const bounds = this.map.getBounds();

      // Calculate the longitude distance of the map's visible area. This allows
      // for an easy way to figure out the center point of the map.
      const distance = this.map.distance(bounds.getNorthWest(), bounds.getNorthEast());

      // Calculate new bounds with the current latitude distance of the visible
      // map from the northwest point of the map. Within these new bounds, the
      // east border is at the center of the map.
      const newBounds = bounds.getNorthWest().toBounds(distance);

      // Set the hint at the top center of the map.
      markerHintTip.setLatLng([bounds.getNorth(), newBounds.getEast()]);
    };
    this.map.on("pm:drawstart", (event) => {
      if (event.shape === "Marker" && !deviceHasFinePointer()) {
        // Hides the "hint marker" as that is confusing for touch screen users.
        const drawMarker = this.map.pm.Draw.Marker;
        drawMarker._hintMarker.setOpacity(0);
        drawMarker._hintMarker.closeTooltip();

        // Creates the touch screen hint "permanently" (while using the tool)
        // sticked at the top of the map.
        markerHintTip = L.tooltip([0, 0], {
          className: "leaflet-tooltip-stickynote",
          content: translate(getLeafletLanguage(), "placeMarkerTip"),
          direction: "bottom",
          permanent: true
        }).addTo(this.map)

        updateHintPosition();
        this.map.on("zoomlevelschange resize move", updateHintPosition, this);
      }
    });
    this.map.on("pm:drawend", (event) => {
      if (event.shape === "Marker" && markerHintTip) {
        markerHintTip.remove();
        markerHintTip = null;
        this.map.off("zoomlevelschange resize move", updateHintPosition, this);
      }
    });
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

  addViewPort(latitude, longitude, zoom) {
    const coordinates = [latitude, longitude];
    this.addMarker(coordinates, "editEv")

    const bounds = new L.LatLngBounds([coordinates])

    this.map.fitBounds(bounds);

    this.map.setZoom(zoom);
  }

  clearShapes() {
    for (let shapeId of Object.keys(this.shapes)) {
      this.deleteShape(shapeId)
    }
  }

  deleteShape(shapeId) {
    const shape = this.shapes[shapeId];
    if (!shape) {
      return;
    }

    Reflect.deleteProperty(this.shapes, shapeId);
    this.map.pm.removeLayer({ target: shape });
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

    const text = translate(getLeafletLanguage(), "fetchingAddress");
    shape.bindPopup(text).openPopup();
  }

  bindNoDataPopup(shapeId) {
    const shape = this.shapes[shapeId];
    if (!shape) {
      return;
    }

    const text = translate(getLeafletLanguage(), "noAddressFound");
    shape.bindPopup(text).openPopup();
  }

  unbindPopup(shapeId) {
    const shape = this.shapes[shapeId];
    shape.closePopup();
    shape.unbindPopup();
  }

  setView(coordinates) {
    this.map.setView(coordinates);
  }

  setAutoAdd(boolean, typeLocButton) {
    this.autoAdd = boolean;

    if (boolean) {
      typeLocButton.classList.add("hidden");
    } else {
      typeLocButton.classList.remove("hidden");
    }
  }
}
