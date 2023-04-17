# frozen_string_literal: true

module Decidim
  module Locations
    # This cell renders the locations on a map. The data given to this cell
    # should be an array of plucked database search results to ensure the
    # performance of the map with many records. The passed data should look as
    # follows:
    # [
    #   [123, "Title of the record", "Summary of the record", "Body text of the record", "Foobar street 123", 1.123, 2.234]
    # ]
    #
    # Each data row should contain the following data in at the following
    # positions:
    #   0: ID of the record
    #   1: Title of the record
    #   2: Translated summary of the record (optional, leave nil if no summary available)
    #   3: Translated body text of the record
    #   4: Address text of the record, e.g. "Foobar street 123"
    #   5: Latitude of the record, e.g. 1.123
    #   6: Longitude of the record, e.g. 2.234
    class MapCell < Decidim::ViewModel
      include Decidim::MapHelper
      include ActionView::Helpers::JavaScriptHelper
      include Decidim::Locations::LocationsHelper

      delegate :snippets, to: :controller

      def show
        return if format_map_locations(model).none?

        render
      end

      def dynamic_markers
        render
      end

      private

      def view_label
        options[:view_label]
      end

      def path_helper
        options[:path_helper]
      end

      def map_type
        options[:type] || "locations"
      end

      def center_coodrdinates
        options[:center_coodrdinates] || markers_center
      end

      def path_for(record_id)
        return unless path_helper

        path_helper.call(record_id)
      end

      def locations_map
        map_options = { type: map_type, markers: markers_data_for_map, zoomControl: false }
        map_options[:center_coordinates] = center_coodrdinates if center_coodrdinates && center_coodrdinates.length > 1

        dynamic_map_for(map_options) do
          yield
        end
      end

      def markers_center
        @markers_center ||= begin
          latitudes = format_map_locations(model).map { |data| data[5].to_f }
          longitudes = format_map_locations(model).map { |data| data[6].to_f }

          [
            latitudes.sum(0.0) / latitudes.size,
            longitudes.sum(0.0) / longitudes.size
          ]
        end
      end

      def markers_data_for_map
        format_map_locations(model).map do |data|
          body = data[2]
          if body.blank?
            doc = Nokogiri::HTML(data[3])
            doc.css("h1, h2, h3, h4, h5, h6").remove

            body = truncate(strip_tags(doc.at("body")&.inner_html), length: 100)
          end

          {
            id: data[0],
            title: data[1],
            body: body,
            address: data[4],
            latitude: data[5],
            longitude: data[6],
            link: path_for(data[0])
          }
        end
      end
    end
  end
end
