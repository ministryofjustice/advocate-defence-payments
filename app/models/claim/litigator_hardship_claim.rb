module Claim
  class LitigatorHardshipClaim < BaseClaim
    route_key_name 'litigators_hardship_claim'

    validates_with ::Claim::LitigatorHardshipClaimValidator
    validates_with ::Claim::LitigatorSupplierNumberValidator
    validates_with ::Claim::LitigatorHardshipClaimSubModelValidator

    has_one :hardship_fee,
            foreign_key: :claim_id,
            class_name: 'Fee::HardshipFee',
            dependent: :destroy,
            inverse_of: :claim,
            validate: proc { |claim| claim.step_validation_required?(:hardship_fees) }

    accepts_nested_attributes_for :hardship_fee, reject_if: :all_blank, allow_destroy: false

    before_validation do
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
          { to_stage: :offence_details }
        ],
        dependencies: %i[case_details]
      },
      {
        name: :offence_details,
        transitions: [
          { to_stage: :hardship_fees }
        ],
        dependencies: %i[case_details defendants]
      },
      {
        name: :hardship_fees,
        transitions: [
          { to_stage: :miscellaneous_fees }
        ],
        dependencies: %i[case_details defendants offence_details]
      },
      {
        name: :miscellaneous_fees,
        transitions: [
          { to_stage: :disbursements }
        ],
        dependencies: %i[hardship_fees]
      },
      {
        name: :disbursements,
        transitions: [
          { to_stage: :travel_expenses }
        ],
        dependencies: %i[hardship_fees]
      },
      {
        name: :travel_expenses,
        transitions: [
          { to_stage: :supporting_evidence }
        ],
        dependencies: %i[hardship_fees]
      },
      { name: :supporting_evidence }
    ].freeze

    def lgfs?
      self.class.lgfs?
    end

    def hardship?
      true
    end

    # TODO: applicable case types unknown. limiting to trial and retrial for now
    def eligible_case_types
      CaseType.interims
    end

    def eligible_misc_fee_types
      Claims::FetchEligibleMiscFeeTypes.new(self).call
    end

    def external_user_type
      :litigator
    end

    private

    def provider_delegator
      provider
    end

    # def cleaner
    #   LitigatorHardshipClaimCleaner.new(self)
    # end

    def assign_total_attrs
      # TODO: understand if this check is really needed
      # left it here mostly to ensure the new changes do
      # not impact anything API related
      return if from_api?
      assign_fees_total(%i[hardship_fee misc_fees]) if fees_changed?
      assign_disbursements_total if disbursements_changed?
      assign_expenses_total if expenses_changed?
      return unless total_changes_required?
      assign_total
      assign_vat
    end

    def total_changes_required?
      [
        hardship_fee_changed?,
        misc_fees_changed?,
        expenses_changed?,
        disbursements_changed?
      ].any?
    end

    def fees_changed?
      hardship_fee_changed? || misc_fees_changed?
    end

    def hardship_fee_changed?
      hardship_fee&.changed?
    end

    def disbursements_changed?
      disbursements.any?(&:changed?)
    end
  end
end