# frozen_string_literal: true

module Decidim
  module Locations
    # This concern can be added in any other command that updates record
    # locations. For example, if you want to update the record locations in
    # UpdateRecord command, you should do the following:
    #
    # 1. Include the Decidim::Locations::LocationsForm concern to the record
    #    form class
    # 2. Add the locations input to the record form view (see README)
    # 3. Include this concern to the UpdateRecord command
    # 4. After the record is updated, call `update_locations(locatable, form)`
    module LocationsCommand
      extend ActiveSupport::Concern

      private

      def update_locations(locatable, form)
        return unless form.locations

        locations = form.locations.map do |location|
          if location.deleted
            locatable.locations.find(location.id).destroy! if location.id.present?
            next
          end

          attributes = {
            address: location.address,
            latitude: location.latitude,
            longitude: location.longitude
          }

          if location.id.present?
            record = locatable.locations.find(location.id)
            record.update!(attributes)
            record
          else
            Decidim::Locations::Location.new(attributes)
          end
        end.compact
        locatable.update!(locations: locations)
      end
    end
  end
end
