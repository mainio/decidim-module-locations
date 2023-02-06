# frozen_string_literal: true

FactoryBot.define do
  factory :location, class: "Decidim::Locations::Location" do
    transient { skip_injection { false } }

    address do
      if skip_injection
        Faker::Address.street_name
      else
        "<script>alert(\"TITLE\");</script> #{Faker::Address.street_name}"
      end
    end
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
  end
end
