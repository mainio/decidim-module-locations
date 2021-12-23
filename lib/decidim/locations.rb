# frozen_string_literal: true

require_relative "locations/version"
require_relative "locations/engine"
require_relative "locations/api"

module Decidim
  module Locations
    autoload :Locatable, "decidim/locations/locatable"
    autoload :QueryExtensions, "decidim/locations/query_extensions"
  end
end
