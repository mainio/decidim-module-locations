# frozen_string_literal: true

module Decidim
  module Locations
    module SurveysTypeExtensions
      extend ActiveSupport::Concern

      included do
        field :geojson, [GraphQL::Types::JSON], "The geojson for all proposal locations under this component", null: true

        def geojson
          component_id = object.id
          survey = Decidim::Surveys::Survey.where(decidim_component_id: component_id).first

          questionnaires = Decidim::Forms::Questionnaire.where(questionnaire_for_id: survey.id)

          locations = questionnaires.map do |questionnaire|
            next if questionnaire.answers.empty?

            questionnaire.answers.map do |answer|
              next if answer.locations.empty?

              answer.locations
            end
          end.flatten.compact

          locations.map do |location|
            answer = Decidim::Forms::Answer.where(id: location.decidim_locations_locatable_id).first
            question = Decidim::Forms::Question.where(id: answer.decidim_question_id).first

            {
              type: "Feature",
              geometry: location.geojson["geometry"],
              properties: {
                id: question.id,
                title: question.body,
                description: question.description,
                type: "Decidim::Forms::Question"
              }
            }
          end
        end
      end
    end
  end
end
