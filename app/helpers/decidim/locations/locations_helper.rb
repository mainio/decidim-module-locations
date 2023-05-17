# frozen_string_literal: true

module Decidim
  module Locations
    module LocationsHelper
      extend ActiveSupport::Concern

      included do
        def geocoding_options
          Decidim::Map.autocomplete(
            organization: current_organization
          ).builder_options.transform_keys { |key| key.to_s.camelize(:lower) }
        end

        def model_has_address?(model)
          model.try(:locations).present?
        end

        def format_map_locations(model)
          query, tbl =
            if model.class.superclass == ActiveRecord::Relation
              [Decidim::Locations::Location.where(locatable: model), model.table_name]
            elsif model.instance_of?(Array)
              return model
            else
              [model.locations, model.class.table_name]
            end

          join_sql = <<~QUERY.squish
            INNER JOIN #{Arel.sql(tbl)} AS locatable
              ON #{Arel.sql(Decidim::Locations::Location.table_name)}.decidim_locations_locatable_id = locatable.id
          QUERY

          response =
            if model.has_attribute?(:description)
              "locatable.description"
            else
              "locatable.body"
            end

          query.joins(join_sql).pluck(
            "locatable.id",
            "locatable.title",
            response,
            :address,
            :latitude,
            :longitude
          ).map do |record|
            # 0: ID of the record
            # 1: Title of the record
            # 2: Translated summary of the record (optional, leave nil if no summary available)
            # 3: Translated body text of the record
            # 4: Address text of the record, e.g. "Foobar street 123"
            # 5: Latitude of the record, e.g. 1.123
            # 6: Longitude of the record, e.g. 2.234
            # [123, "Title of the record", "Summary of the record", "Body text of the record", "Foobar street 123", 1.123, 2.234]
            title = translated_attribute(JSON.parse(record[1]))
            body =
              begin
                translated_attribute(JSON.parse(record[2]))
              rescue JSON::ParserError
                translated_attribute(record[2])
              end
            [record[0], title, nil, body, record[3], record[4], record[5]]
          end
        end
      end
    end
  end
end
