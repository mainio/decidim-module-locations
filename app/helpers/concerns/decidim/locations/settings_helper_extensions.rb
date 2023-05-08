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
          scope: :scope_field,
          enum: :collection_radio_buttons,
          time: :datetime_field
        }.freeze)
      end
    end
  end
end
