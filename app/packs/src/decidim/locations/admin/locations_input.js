import AutoLabelByPositionComponent from "src/decidim/admin/auto_label_by_position.component"
import AutoButtonsByPositionComponent from "src/decidim/admin/auto_buttons_by_position.component"
import createDynamicFields from "src/decidim/admin/dynamic_fields.component"
import createSortList from "src/decidim/admin/sort_list.component"

const wrapperSelector = ".location-items";
const fieldSelector = ".location-item";

const autoLabelByPosition = new AutoLabelByPositionComponent({
  listSelector: ".location-item:not(.hidden)",
  labelSelector: ".card-title span:first",
  onPositionComputed: (el, idx) => {
    $(el).find("input[name$=\\[position\\]]").val(idx);
  }
});

const autoButtonsByPosition = new AutoButtonsByPositionComponent({
  listSelector: ".location-item:not(.hidden)",
  hideOnFirstSelector: ".move-up-location-item",
  hideOnLastSelector: ".move-down-location-item"
});

const createSortableList = () => {
  createSortList(".location-items-list:not(.published)", {
    handle: ".location-item-divider",
    placeholder: '<div style="border-style: dashed; border-color: #000"></div>',
    forcePlaceholderSize: true,
    onSortUpdate: () => { autoLabelByPosition.run() }
  });
};

const hideDeletedItem = ($target) => {
  const inputDeleted = $target.find("input[name$=\\[deleted\\]]").val();

  if (inputDeleted === "true") {
    $target.addClass("hidden");
    $target.hide();
  }
};

$(() => {
  createDynamicFields({
    placeholderId: "location-id",
    wrapperSelector: wrapperSelector,
    containerSelector: ".location-items-list",
    fieldSelector: fieldSelector,
    addFieldButtonSelector: ".add-location-item",
    removeFieldButtonSelector: ".remove-location-item",
    moveUpFieldButtonSelector: ".move-up-location-item",
    moveDownFieldButtonSelector: ".move-down-location-item",
    onAddField: () => {
      createSortableList();

      autoLabelByPosition.run();
      autoButtonsByPosition.run();
    },
    onRemoveField: () => {
      autoLabelByPosition.run();
      autoButtonsByPosition.run();
    },
    onMoveUpField: () => {
      autoLabelByPosition.run();
      autoButtonsByPosition.run();
    },
    onMoveDownField: () => {
      autoLabelByPosition.run();
      autoButtonsByPosition.run();
    }
  });

  createSortableList();

  $(fieldSelector).each((_i, el) => {
    const $target = $(el);

    hideDeletedItem($target);
  });

  autoLabelByPosition.run();
  autoButtonsByPosition.run();
});
