const initializeTabs = function (wrapperEl) {
  const mapEl = wrapperEl.querySelector("[data-decidim-map]");
  const ctrl = $(mapEl).data("map-controller");
  const tabsEl = wrapperEl.querySelector('[data-map-container="#pick_model_locations_map"]');
  const typeLocWrapperEl = wrapperEl.querySelector(".type-locations-wrapper");
  const mainTabs = tabsEl.querySelectorAll(":scope > li");
  const moreTabs = tabsEl.querySelector("[data-more-tabs]").querySelectorAll(":scope > li");
  const transparentActions = ["clear-markers"];

  let activeTab = null;

  const setActiveTab = (action) => {
    const wasActivated = activeTab === action;

    if (wasActivated) {
      activeTab = null;
    } else {
      mainTabs.forEach((li) => li.classList.remove("is-active"));
      activeTab = action;
    }

    const activeLi = tabsEl.querySelector(`:scope > li[data-action="${action}"]`);
    if (activeLi) {
      if (wasActivated) {
        activeLi.classList.remove("is-active");
      } else {
        activeLi.classList.add("is-active");
      }
    }
  };

  const handleActionTab = (action) => {
    const wasActivated = activeTab === action;

    if (!transparentActions.includes(action)) {
      setActiveTab(action);

      ctrl.disablePlaceMarkers();
      typeLocWrapperEl.classList.add("hide");
      if (wasActivated) {
        return;
      }
    }

    if (action === "add-markers") {
      ctrl.enablePlaceMarkers();
    } else if (action === "type-loc") {
      typeLocWrapperEl.classList.remove("hide");
    } else if (action === "clear-markers") {
      ctrl.clearMarkers();
    }
  };

  if (Object.keys(ctrl.markers).length === 0) {
    handleActionTab("add-markers");
  }

  mainTabs.forEach((li) => {
    const action = li.dataset.action;
    if (action === "more") {
      return;
    }

    li.querySelector(":scope > a").addEventListener("click", (ev) => {
      ev.preventDefault();
      handleActionTab(action);
    });
  });

  moreTabs.forEach((li) => {
    const action = li.dataset.action;
    li.querySelector(":scope > a").addEventListener("click", (ev) => {
      ev.preventDefault();
      handleActionTab(action);
    })
  });
};

export default initializeTabs;
