# frozen_string_literal: true

require_relative "locations/version"
require_relative "locations/engine"
require_relative "locations/api"

module Decidim
  module Locations
    autoload :Locatable, "decidim/locations/locatable"
    autoload :QueryExtensions, "decidim/locations/query_extensions"
    autoload :SettingsManifestExtensions, "decidim/locations/settings_manifest_extensions"
    autoload :LocationSerializer, "decidim/locations/location_serializer"
    autoload :ProposalsTypeExtensions, "decidim/locations/api/concerns/proposals_type_extensions.rb"
    autoload :MeetingsTypeExtensions, "decidim/locations/api/concerns/meetings_type_extensions.rb"
    autoload :AccountabilityTypeExtensions, "decidim/locations/api/concerns/accountability_type_extensions.rb"
  end
end
