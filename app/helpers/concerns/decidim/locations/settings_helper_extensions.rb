# frozen_string_literal: true

module Decidim
  module Locations
    module SettingsHelperExtensions
      extend ActiveSupport::Concern

      included do
        remove_const("TYPES")
        const_set("TYPES", {
          boolean: :check_box,
          integer: :number_field,
          string: :text_field,
          float: :number_field,
          text: :text_area,
          select: :select_field,
          enum: :collection_radio_buttons,
          time: :datetime_field,
          integer_with_units: :integer_with_units,
          taxonomy_filters: :taxonomy_filters
        }.freeze)
      end
    end
  end
end
