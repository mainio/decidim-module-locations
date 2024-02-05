# frozen_string_literal: true

class TransferExistingLocations < ActiveRecord::Migration[6.1]
  def up
    coord_columns = %w(latitude longitude)

    tables_with_columns = ActiveRecord::Base.connection.tables.select do |table|
      coord_columns.all? { |column| ActiveRecord::Base.connection.column_exists?(table, column) }
    end

    tables_with_columns.delete("decidim_locations_locations")

    tables_with_columns.each do |table|
      execute <<-SQL.squish
        SELECT id, latitude, longitude from #{table}
      SQL
    end

    execute <<-SQL.squish
      INSERT INTO decidim_locations_locations (address, latitude, longitude, shape, geojson, decidim_locations_locatable_type, decidim_locations_locatable_id)
      VALUES
        ()
    SQL
  end
end
