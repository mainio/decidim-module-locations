# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Locations
    describe LocationsCommand do
      let!(:organization) { create(:organization) }
      let(:user) { create(:user, :admin, :confirmed, organization: organization) }
      let(:dummy) { create(:dummy_resource) }
      let!(:form_klass) { Decidim::DummyResources::DummyResourceForm }
      let(:form_params) do
        {
          title: "This title has to be at least 15 chars",
          body: "This body has to be at least 15 chars",
          locations: locations
        }
      end

      let(:locations) do
        [
          {
            address: "Test street",
            latitude: 11,
            longitude: 4
          }
        ]
      end

      let(:form) do
        form_klass.from_params(
          form_params
        ).with_context(
          current_organization: organization,
          current_user: user
        )
      end

      let(:command_class) do
        Class.new(Decidim::Command) do
          include Decidim::Locations::LocationsCommand

          def initialize(form, dummy)
            @form = form
            @dummy = dummy
          end

          def call
            update_dummy

            update_locations(@dummy, @form)

            broadcast(:ok, @dummy)
          end

          private

          def update_dummy
            @dummy.update(title: { en: @form.title }, body: @form.body)
          end
        end
      end

      context "when command called" do
        it "broadcasts ok" do
          expect do
            command_class.call(form, dummy)
          end.to broadcast(:ok)
        end
      end

      context "when no locations" do
        it "adds them" do
          command_class.call(form, dummy)
          expect(dummy.locations.order(:id).map do |loc|
            loc.attributes.transform_keys(&:to_sym).slice(:address, :latitude, :longitude)
          end).to eq(locations)
        end
      end

      context "when locations changed" do
        let!(:dummy_locs) { create(:location, locatable: dummy, address: "Original address", latitude: 12, longitude: 5) }

        it "updates locations" do
          expect(dummy.locations.order(:id).map do |loc|
            loc.attributes.transform_keys(&:to_sym).slice(:address, :latitude, :longitude)
          end).to eq([{ address: "Original address", latitude: 12, longitude: 5 }])

          command_class.call(form, dummy)
          expect(dummy.locations.order(:id).map do |loc|
            loc.attributes.transform_keys(&:to_sym).slice(:address, :latitude, :longitude)
          end).to eq(locations)
        end
      end
    end
  end
end
