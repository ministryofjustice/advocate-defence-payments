module API
  module Entities
    class FullClaim < BaseEntity
      expose :uuid, as: :claim_uuid

      expose :claim_details do
        expose :type, as: :claim_type
        expose :supplier_number, as: :supplier_account_code
        expose :advocate_category
        expose :additional_information
        expose :apply_vat, format_with: :bool_char
        expose :state
        expose :last_submitted_at, as: :submitted_at, format_with: :utc
        expose :original_submission_date, as: :originally_submitted_at, format_with: :utc
        expose :authorised_at, format_with: :utc
        expose :creator, as: :created_by, using: API::Entities::ExternalUser
        expose :external_user, using: API::Entities::ExternalUser
      end

      expose :case_details do
        expose :case_type_name, as: :case_type
        expose :case_type_uuid
        expose :case_number
        expose :cms_number
        expose :providers_ref, as: :providers_reference

        expose :court_code
        # expose :transfer_court, if: lambda { |instance, _opts| instance.transfer_court.present? || instance.transfer_case_number.present? } do
        #   expose :transfer_court_code
        #   expose :transfer_case_number, as: :case_number
        # end

        expose :offence do |instance, options|
          API::Entities::Offence.represent instance.offence, options.merge(export_format: true)
        end

        expose :trial_dates do
          expose :first_day_of_trial, as: :date_started, format_with: :utc
          expose :trial_concluded_at, as: :date_concluded, format_with: :utc
          expose :estimated_trial_length, as: :estimated_length
          expose :actual_trial_length, as: :actual_length
        end

        expose :retrial_dates do
          expose :retrial_started_at, as: :date_started, format_with: :utc
          expose :retrial_concluded_at, as: :date_concluded, format_with: :utc
          expose :retrial_estimated_length, as: :estimated_length
          expose :retrial_actual_length, as: :actual_length
        end

        expose :cracked_dates do
          with_options(format_with: :utc) do
            expose :trial_fixed_notice_at, as: :date_fixed_notice
            expose :trial_fixed_at, as: :date_fixed
            expose :trial_cracked_at, as: :date_cracked
          end
          expose :trial_cracked_at_third, as: :date_cracked_at_third
        end

        # expose :object, as: :totals, using: API::Entities::Totals
      end

      expose :defendants, using: API::Entities::Export::Defendant

      expose :fees, using: API::Entities::Fee
      expose :expenses, using: API::Entities::Expense

      # TODO: not needed for now, CCR only needs the very basic
      # expose :disbursements, using: API::Entities::Disbursement
      # expose :documents, using: API::Entities::Document
      # expose :messages, using: API::Entities::Message
      # expose :assessment, using: API::Entities::Determination
      # expose :redeterminations, using: API::Entities::Determination

      private

      def case_type_name
        object.case_type.name
      end

      def case_type_uuid
        object.case_type.uuid
      end

      def court_code
        object.court&.code
      end

      def transfer_court_code
        object.transfer_court&.code
      end

      def advocate_category
        ::CCR::AdvocateCategoryAdapter.code_for(object.advocate_category) if object.advocate_category.present?
      end
    end
  end
end
