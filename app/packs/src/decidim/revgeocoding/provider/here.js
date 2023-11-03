import "src/decidim/geocoding"
import formatAddress from "src/decidim/geocoding/format_address"

/**
 * For the available address format keys, refer to:
 * https://developer.here.com/documentation/geocoder-autocomplete/dev_guide/topics/resource-type-response-suggest.html
 */
$(() => {
  const generateAddressLabel = formatAddress;

  $("[data-decidim-revgeocoding]").each((_i, el) => {
    const $el = $(el);
    const config = $el.data("decidim-revgeocoding");
    const addressFormat = config.addressFormat || [
      ["street", "houseNumber"],
      "district",
      "city",
      "county",
      "state",
      "countryName"
    ];
    const language = $("html").attr("lang");

    if (!config.apiKey || config.apiKey.length < 1) {
      return;
    }

    // reverse geocoding
    $el.on("geocoder-reverse.decidim", (_ev, latlng, extraData) => {
      // radius in meters
      const radius = 100000;
      $.ajax({
        method: "GET",
        url: "https://revgeocode.search.hereapi.com/v1/revgeocode",
        data: {
          lang: language,
          apiKey: config.apiKey,
          in: `circle:${latlng.lat},${latlng.lng};r=${radius}`,
          types: "address"
        },
        dataType: "json"
      }).done((resp) => {
        if (!resp.items || !Array.isArray(resp.items) || resp.items.length < 1) {
          $el.trigger("no-address",
            { ...extraData }
          );
          return;
        }

        const returnedAddress = resp.items[0].address;
        if (!returnedAddress) {
          $el.trigger("no-address",
            { ...extraData }
          );
          return;
        }

        const modifiedAddress = {};

        Object.keys(returnedAddress).forEach((key) => {
          modifiedAddress[key.replace(/^./, key[0].toLowerCase())] = returnedAddress[key];
        });
        const label = generateAddressLabel(modifiedAddress, addressFormat);

        $el.trigger("marker-address", [
          { address: label, position: latlng, ...extraData }
        ]);
      });
    });
  })
})
