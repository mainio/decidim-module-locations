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
      "country"
    ];
    const language = $("html").attr("lang");

    if (!config.apiKey || config.apiKey.length < 1) {
      return;
    }

    // reverse geocoding
    $el.on("geocoder-reverse.decidim", (_ev, latlng, extraData) => {
      // radius in meters
      const radius = 500;
      $.ajax({
        method: "GET",
        url: "https://reverse.geocoder.ls.hereapi.com/6.2/reversegeocode.json",
        data: {
          language,
          apiKey: config.apiKey,
          prox: `${latlng.lat},${latlng.lng},${radius}`,
          mode: "retrieveAddresses"
        },
        dataType: "json"
      }).done((resp) => {
        if (!resp.Response || !Array.isArray(resp.Response.View) ||
          resp.Response.View.length < 1
        ) {
          return;
        }
        const view = resp.Response.View[0];
        if (!Array.isArray(view.Result) || view.Result.length < 1) {
          return;
        }

        const returnedAddress = view.Result[0].Location.Address;

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
