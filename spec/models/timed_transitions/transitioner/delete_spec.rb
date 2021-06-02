require 'rails_helper'
require 'models/timed_transitions/transitioner/shared_examples'

RSpec.describe TimedTransitions::Transitioner::Delete do
  context 'with an archived pending delete claim' do
    let(:claim) { create :litigator_claim, :archived_pending_delete, case_number: 'A20164444' }


    include_examples 'transitioning to destroyed'

    context 'when last state transition more than 16 weeks ago' do
      subject(:run_transitioner) { described_class.new(claim).run }

      before do
        travel_to(17.weeks.ago) do
          claim
        end
      end

      it { expect { transitioner.run }.to change(CaseWorkerClaim.where(claim_id: claim.id), :count).to 0 }
    end
  end

  context 'with a draft claim' do
    let(:claim) { create :litigator_claim, :draft }

    include_examples 'transitioning to destroyed'
  end
end
