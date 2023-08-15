# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Locations
    RSpec.describe LocationAttributes do
      describe "arguments" do
        subject { described_class.arguments }

        it "defines the id argument" do
          expect(subject["id"].type).to eq(GraphQL::Types::ID)
        end

        it "defines the geocode argument" do
          expect(subject["geocode"].type).to eq(GraphQL::Types::Boolean)
          expect(subject["geocode"].default_value).to be false
        end

        it "defines the address argument" do
          expect(subject["address"].type).to eq(GraphQL::Types::String)
        end

        it "defines the latitude argument" do
          expect(subject["latitude"].type).to eq(GraphQL::Types::Float)
        end

        it "defines the longitude argument" do
          expect(subject["longitude"].type).to eq(GraphQL::Types::Float)
        end
      end
    end
  end
end
