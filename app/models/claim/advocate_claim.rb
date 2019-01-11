# == Schema Information
#
# Table name: claims
#
#  id                       :integer          not null, primary key
#  additional_information   :text
#  apply_vat                :boolean
#  state                    :string
#  last_submitted_at        :datetime
#  case_number              :string
#  advocate_category        :string
#  first_day_of_trial       :date
#  estimated_trial_length   :integer          default(0)
#  actual_trial_length      :integer          default(0)
#  fees_total               :decimal(, )      default(0.0)
#  expenses_total           :decimal(, )      default(0.0)
#  total                    :decimal(, )      default(0.0)
#  external_user_id         :integer
#  court_id                 :integer
#  offence_id               :integer
#  created_at               :datetime
#  updated_at               :datetime
#  valid_until              :datetime
#  cms_number               :string
#  authorised_at            :datetime
#  creator_id               :integer
#  evidence_notes           :text
#  evidence_checklist_ids   :string
#  trial_concluded_at       :date
#  trial_fixed_notice_at    :date
#  trial_fixed_at           :date
#  trial_cracked_at         :date
#  trial_cracked_at_third   :string
#  source                   :string
#  vat_amount               :decimal(, )      default(0.0)
#  uuid                     :uuid
#  case_type_id             :integer
#  form_id                  :string
#  original_submission_date :datetime
#  retrial_started_at       :date
#  retrial_estimated_length :integer          default(0)
#  retrial_actual_length    :integer          default(0)
#  retrial_concluded_at     :date
#  type                     :string
#  disbursements_total      :decimal(, )      default(0.0)
#  case_concluded_at        :date
#  transfer_court_id        :integer
#  supplier_number          :string
#  effective_pcmh_date      :date
#  legal_aid_transfer_date  :date
#  allocation_type          :string
#  transfer_case_number     :string
#  clone_source_id          :integer
#  last_edited_at           :datetime
#  deleted_at               :datetime
#  providers_ref            :string
#  disk_evidence            :boolean          default(FALSE)
#  fees_vat                 :decimal(, )      default(0.0)
#  expenses_vat             :decimal(, )      default(0.0)
#  disbursements_vat        :decimal(, )      default(0.0)
#  value_band_id            :integer
#  retrial_reduction        :boolean          default(FALSE)
#

module Claim
  class AdvocateClaim < BaseClaim
    route_key_name 'advocates_claim'

    has_many :basic_fees,
             foreign_key: :claim_id,
             class_name: 'Fee::BasicFee',
             dependent: :destroy,
             inverse_of: :claim,
             validate: proc { |claim| claim.step_validation_required?(:basic_fees) }
    has_many :fixed_fees, -> { reorder(:fee_type_id) },
             foreign_key: :claim_id,
             class_name: 'Fee::FixedFee',
             dependent: :destroy,
             inverse_of: :claim,
             validate: proc { |claim| claim.step_validation_required?(:fixed_fees) }
    has_one :interim_claim_info,
            foreign_key: :claim_id,
            dependent: :destroy,
            inverse_of: :claim,
            validate: proc { |claim| claim.step_validation_required?(:miscellaneous_fees) }

    accepts_nested_attributes_for :basic_fees, reject_if: all_blank_or_zero, allow_destroy: true
    accepts_nested_attributes_for :fixed_fees, reject_if: all_blank_or_zero, allow_destroy: true
    accepts_nested_attributes_for :interim_claim_info, reject_if: :all_blank, allow_destroy: false

    validates_with ::Claim::AdvocateClaimValidator, unless: proc { |c| c.disable_for_state_transition.eql?(:all) }
    validates_with ::Claim::AdvocateClaimSubModelValidator

    delegate :requires_cracked_dates?, to: :case_type, allow_nil: true

    after_initialize do
      instantiate_basic_fees
    end

    before_validation do
      set_supplier_number
      assign_total_attrs
    end

    SUBMISSION_STAGES = [
      {
        name: :case_details,
        transitions: [
          { to_stage: :defendants }
        ]
      },
      {
        name: :defendants,
        transitions: [
          {
            to_stage: :offence_details,
            condition: ->(claim) { !claim.fixed_fee_case? }
          },
          {
            to_stage: :fixed_fees,
            condition: ->(claim) { claim.fixed_fee_case? }
          }
        ],
        dependencies: %i[case_details]
      },
      {
        name: :offence_details,
        transitions: [
          { to_stage: :basic_fees }
        ],
        dependencies: %i[case_details defendants]
      },
      {
        name: :basic_fees,
        transitions: [
          { to_stage: :miscellaneous_fees }
        ],
        dependencies: %i[case_details defendants offence_details]
      },
      {
        name: :fixed_fees,
        transitions: [
          { to_stage: :miscellaneous_fees }
        ],
        dependencies: %i[case_details defendants]
      },
      {
        name: :miscellaneous_fees,
        transitions: [
          { to_stage: :travel_expenses }
        ]
      },
      {
        name: :travel_expenses,
        transitions: [
          { to_stage: :supporting_evidence }
        ]
      },
      { name: :supporting_evidence }
    ].freeze

    def assign_total_attrs
      # TODO: understand if this check is really needed
      # left it here mostly to ensure the new changes do
      # not impact anything API related
      return if from_api?
      assign_fees_total(%i[basic_fees fixed_fees misc_fees]) if fees_changed?
      assign_expenses_total if expenses_changed?
      return unless total_changes_required?
      assign_total
      assign_vat
    end

    def total_changes_required?
      fees_changed? || expenses_changed?
    end

    def fees_changed?
      %i[basic fixed misc].any? { |fee_type| public_send("#{fee_type}_fees_changed?") }
    end

    def basic_fees_changed?
      basic_fees.any?(&:changed?)
    end

    def fixed_fees_changed?
      fixed_fees.any?(&:changed?)
    end

    def eligible_case_types
      CaseType.agfs
    end

    def eligible_basic_fee_types
      # TODO: this should return a list based on the current given fee scheme
      # rather than conditionally return scheme 10 specifically
      # TBD once all the fee scheme work is integrated
      return Fee::BasicFeeType.all if from_json_import?
      return Fee::BasicFeeType.unscoped.agfs_scheme_10s.order(:position) if agfs_reform?
      Fee::BasicFeeType.agfs_scheme_9s
    end

    def eligible_misc_fee_types
      Claims::FetchEligibleMiscFeeTypes.new(self).call
    end

    def eligible_fixed_fee_types
      Claims::FetchEligibleFixedFeeTypes.new(self).call
    end

    def external_user_type
      :advocate
    end

    def agfs?
      self.class.agfs?
    end

    def final?
      true
    end

    def eligible_advocate_categories
      Claims::FetchEligibleAdvocateCategories.for(self)
    end

    def update_claim_document_owners
      documents.each { |d| d.update_column(:external_user_id, external_user_id) }
    end

    private

    def provider_delegator
      if provider.firm?
        provider
      elsif provider.chamber?
        external_user
      else
        raise "Unknown provider type: #{provider.provider_type}"
      end
    end

    def agfs_supplier_number
      if provider.firm?
        provider.firm_agfs_supplier_number
      else
        external_user.supplier_number
      end
    rescue StandardError
      nil
    end

    def set_supplier_number
      supplier_no = agfs_supplier_number
      self.supplier_number = supplier_no if supplier_number != supplier_no
    end

    # create a blank fee for every basic fee type not passed to Claim::AdvocateClaim.new
    def instantiate_basic_fees
      return unless case_type.present? && !case_type.is_fixed_fee?
      return unless editable?

      fee_type_ids = basic_fees.map(&:fee_type_id)
      eligible_basic_fee_type_ids = eligible_basic_fee_types.map(&:id)
      not_eligible_ids = fee_type_ids - eligible_basic_fee_type_ids
      self.basic_fees = basic_fees.reject { |fee| not_eligible_ids.include?(fee.fee_type_id) }
      eligible_basic_fee_types.each do |basic_fee_type|
        next if fee_type_ids.include?(basic_fee_type.id)
        basic_fees.build(fee_type: basic_fee_type, quantity: 0, amount: 0)
      end
    end

    def destroy_all_invalid_fee_types
      if case_type.present? && case_type.is_fixed_fee?
        basic_fees.map(&:clear) unless basic_fees.empty?
        applicable_fees = Claims::FetchEligibleFixedFeeTypes.new(self).call
        fixed_fees.each do |persisted_fee|
          fixed_fees.delete(persisted_fee) unless applicable_fees.map(&:code).include?(persisted_fee.fee_type_code)
        end
      else
        fixed_fees.destroy_all unless fixed_fees.empty?
      end
    end

    def clear_inapplicable_fields
      clear_cracked_details if case_type.present? && !requires_cracked_dates?
    end

    def clear_cracked_details
      self.trial_fixed_notice_at = nil if trial_fixed_notice_at
      self.trial_fixed_at = nil if trial_fixed_at
      self.trial_cracked_at = nil if trial_cracked_at
      self.trial_cracked_at_third = nil if trial_cracked_at_third
    end
  end
end
