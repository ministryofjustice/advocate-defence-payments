require_relative 'claim_state_advancer'
require_relative 'document_generator'
require_relative 'basic_fee_generator'
require_relative 'fee_generator'
require_relative 'expense_generator'
require_relative 'disbursement_generator'

module DemoData

  class BaseClaimGenerator

    def initialize(param_options = {})
      raise "You cannot instantiate a generator of class #{self.class}" if self.class == BaseClaimGenerator
      default_options = { states: :all, num_external_users: 2, num_claims_per_state: 2 }
      options = default_options.merge(param_options)
      @states = options[:states] == :all ? Claims::StateMachine.dashboard_displayable_states : options[:states]
      @num_external_users = options[:num_external_users]
      @num_claims = options[:num_claims_per_state]
      @external_user_persona = self.instance_of?(DemoData::LitigatorClaimGenerator) ? :litigator : :advocate
    end

    def run
      generate_external_user_if_required

      if @external_user_persona == :advocate
        external_users = ExternalUser.advocates[0, @num_external_users]
      elsif @external_user_persona == :litigator
        external_users = ExternalUser.litigators[0, @num_external_users]
      end

      external_users.each do |external_user|
        @num_claims.times do
          generate_claims_for_external_user(external_user)
        end
      end

    end

  private

    def add_claim_detail(claim)
      add_trial_dates(claim) if claim.case_type.requires_trial_dates?
      add_retrial_dates(claim) if claim.case_type.requires_retrial_dates?
      add_cracked_dates(claim) if claim.case_type.requires_cracked_dates?
    end

    def add_fees(claim)
      add_basic_fees(claim) unless claim.case_type.is_fixed_fee?
      add_fixed_fees(claim) if claim.case_type.is_fixed_fee?
      add_misc_fees(claim)
    end

    def add_trial_dates(claim)
      claim.first_day_of_trial     = rand(60..90).days.ago
      claim.estimated_trial_length = rand(4..60)
      claim.actual_trial_length    = claim.estimated_trial_length + rand(-2..5)
      claim.trial_concluded_at     = claim.first_day_of_trial + (claim.actual_trial_length / 5 * 7).days
    end

    def add_retrial_dates(claim)
      claim.retrial_started_at       = rand(30..40).days.ago
      claim.retrial_estimated_length = rand(4..60)
      claim.retrial_actual_length    = claim.retrial_estimated_length + rand(-2..5)
      claim.retrial_concluded_at     = claim.retrial_started_at + (claim.retrial_actual_length / 5 * 7).days
    end

    def add_cracked_dates(claim)
      claim.trial_fixed_notice_at  = rand(70..90).days.ago
      claim.trial_fixed_at         = claim.trial_fixed_notice_at + rand(20..30).days
      claim.trial_cracked_at       = claim.trial_fixed_at + rand(5..10).days
      claim.trial_cracked_at_third = populate_cracked_at_third(claim)
    end

    def populate_cracked_at_third(claim)
      if claim.case_type.name == 'Cracked Trial'
        claim.trial_cracked_at_third = [ 'first_third', 'second_third', 'final_third'].sample
      else
        claim.trial_cracked_at_third = 'final_third'
      end
    end

    def add_defendants(claim)
      rand(1..5).times { FactoryGirl.create(:defendant, claim: claim) }
      claim.save!
      claim.reload
    end

    def add_documents(claim)
      DocumentGenerator.new(claim).generate!
    end

    def add_basic_fees(claim)
      BasicFeeGenerator.new(claim).generate!
    end

    def add_misc_fees(claim)
      FeeGenerator.new(claim, Fee::MiscFeeType).generate!
    end

    def add_fixed_fees(claim)
      FeeGenerator.new(claim, Fee::FixedFeeType).generate!
    end

    def add_expenses(claim)
      ExpenseGenerator.new(claim).generate!
    end

    def add_disbursements(claim)
      DisbursementGenerator.new(claim).generate!
    end

    def advance_claim_to_state(claim, state)
      begin
        ClaimStateAdvancer.new(claim).advance_to(state)
      rescue => err
        puts "ERROR: #{err.class} :: #{err.message}"
        ap claim
        ap claim.assessment
        raise err
      end
    end

    def generate_claim_in_state_for_external_user(state, external_user)
      claim = generate_claim(external_user) # see sub classes for implementation
      advance_claim_to_state(claim, state)
      add_certification(claim) if !claim.draft?
    end

    def generate_claims_for_external_user(external_user)
      @states.each { |state| generate_claim_in_state_for_external_user(state, external_user) }
    end

    def generate_external_user_if_required
      num_external_users_existing = ExternalUser.__send__(@external_user_persona.to_s.pluralize.to_sym).count
      num_external_users_required = @num_external_users - num_external_users_existing
      num_external_users_required.times do
        FactoryGirl.create(:external_user, @external_user_persona)
      end
    end

    def generate_additional_info
      [
        'It was the best of times, it was the worst of times.',
        'Last night I dreamt of Manderley again.',
        'It is a truth universally acknowledged, that a single man in possession of a good fortune must be in want of a wife.',
        'Happy families are all alike; every unhappy family is unhappy in its own way.',
        'It was a bright cold day in April, and the clocks were striking thirteen.',
        'I am an invisible man.',
        'Stately, plump Buck Mulligan came from the stairhead, bearing a bowl of lather on which a mirror and a razor lay crossed.',
        'All this happened, more or less.',
        'The moment one learns English, complications set in.',
        'He was an old man who fished alone in a skiff in the Gulf Stream and he had gone eighty-four days now without taking a fish.',
        'It was the day my grandmother exploded.',
        'It was love at first sight. The first time Yossarian saw the chaplain, he fell madly in love with him.',
        'I have never begun a novel with more misgiving.',
        'You better not never tell nobody but God.',
        'The past is a foreign country; they do things differently there.',
        'He was born with a gift of laughter and a sense that the world was mad.',
        'In the town, there were two mutes and they were always together.',
        'The cold passed reluctantly from the earth, and the retiring fogs revealed an army stretched out on the hills, resting.'
      ].sample
    end

  end

end
