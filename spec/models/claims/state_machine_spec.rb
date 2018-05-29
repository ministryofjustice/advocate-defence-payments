require 'rails_helper'

RSpec.describe Claims::StateMachine, type: :model do
  subject(:claim) { create(:advocate_claim) }

  describe 'all available states' do
    let(:states) do
      [
        :allocated,
        :archived_pending_delete,
        :awaiting_written_reasons,
        :deleted,
        :draft,
        :authorised,
        :part_authorised,
        :refused,
        :rejected,
        :redetermination,
        :submitted,
        :deallocated
      ]
    end

    it('exist') { expect(Claim::BaseClaim.active.state_machine.states.map(&:name).sort).to eq(states.sort) }
  end

  describe 'NON_VALIDATION_STATES' do
    subject { Claims::StateMachine::NON_VALIDATION_STATES }

    let(:states) { Claim::BaseClaim.active.state_machine.states.map(&:name).sort }
    it { is_expected.to eql (states - [:draft, :submitted]).map(&:to_s) }
  end

  describe '#around_transition' do
    let(:claim) { create(:submitted_claim) }
    let(:case_type) { create(:case_type, :cbr) }

    context 'sets flag to disable all validations' do
      TRANSITION_EVENT_CHAINS = {
        allocate: %i[allocate!],
        archive_pending_delete: %i[allocate! refuse! archive_pending_delete!],
        await_written_reasons: %i[allocate! refuse! await_written_reasons!],
        deallocate: %i[allocate! deallocate!],
        redetermine: %i[allocate! reject! redetermine!],
        refuse: %i[allocate! refuse!],
        reject: %i[allocate! reject!]
      }

      TRANSITION_EVENT_CHAINS.each do |transition, events|
        context "when transitioning via event chain #{events}" do
          before do
            *precursor_events, _event = events
            precursor_events.each { |event| claim.send(event) }
          end

          it "##{events.last}" do
            expect(claim).to receive(:disable_for_state_transition=).with(:all).exactly(1).times
            expect(claim).to receive(:disable_for_state_transition=).with(nil).exactly(1).times
            claim.send(events.last)
          end
        end
      end
    end

    context 'sets flag to enable only assessment validations' do
      before do
        claim.allocate!
        claim.update_amount_assessed(fees: 100.00)
      end

      %i[authorise! authorise_part!].each do |transition|
        it "when transitioning via ##{transition}" do
          expect(claim).to receive(:disable_for_state_transition=).with(:only_amount_assessed).exactly(1).times
          expect(claim).to receive(:disable_for_state_transition=).with(nil).exactly(1).times
          claim.send(transition)
        end
      end
    end
  end

  describe 'valid transitions' do
    describe 'from redetermination' do
      before { subject.submit! }

      it { expect{ subject.allocate! }.to change{ subject.state }.to('allocated') }
    end

    describe 'from awaiting_written_reasons' do
      before { subject.submit! }

      it { expect{ subject.allocate! }.to change{ subject.state }.to('allocated') }
    end

    describe 'from allocated' do
      before do
        subject.submit!
        subject.allocate!
      end

      it { expect{ subject.reject! }.to      change{ subject.state }.to('rejected') }
      it { expect{ subject.submit! }.to      change{ subject.state }.to('submitted') }
      it { expect{ subject.refuse! }.to      change{ subject.state }.to('refused') }

      it {
        expect{
          subject.assessment.update(fees: 100.00, expenses: 23.45)
          subject.authorise_part!
        }.to change{ subject.state }.to('part_authorised') }

      it { expect{
        subject.assessment.update(fees: 100.00, expenses: 23.45)
        subject.authorise!
      }.to change{ subject.state }.to('authorised') }

      it { expect{ subject.archive_pending_delete! }.to raise_error(StateMachines::InvalidTransition) }

      it 'should be able to deallocate' do
        expect{
          subject.deallocate!
        }.to change{ subject.state }.to('submitted')
      end

      it 'should unlink case workers on deallocate' do
        expect(subject.case_workers).to receive(:destroy_all)
        subject.deallocate!
      end

      context 'when a claim exists with a, legacy, now non-valid evidence provision fee' do
        let(:claim) { create :litigator_claim, force_validation: true }
        let(:fee) { build :misc_fee, claim: claim, amount: '123', fee_type: fee_type }
        let(:fee_type) { build :misc_fee_type, :mievi }

        describe 'de-allocation' do
          it { expect{ subject.deallocate! }.not_to raise_error }
        end

        describe 'part-authorising' do
          it {
            expect{
              subject.assessment.update(fees: 100.00, expenses: 23.45)
              subject.authorise_part!
            }.to change{ subject.state }.to('part_authorised')
          }
        end
      end
    end

    describe 'from draft' do
      it { expect{ subject.submit! }.to change{ subject.state }.to('submitted') }
      it { expect{ subject.archive_pending_delete! }.to raise_error(StateMachines::InvalidTransition) }
    end

    describe 'from authorised' do
      before {
        subject.submit!
        subject.allocate!
        subject.assessment.update(fees: 100.00, expenses: 23.45)
        subject.authorise!
      }

      it { expect{ subject.redetermine! }.to change{ subject.state }.to('redetermination') }
      it { expect{ subject.archive_pending_delete! }.to change{ subject.state }.to('archived_pending_delete') }
    end

    describe 'from part_authorised' do
      before {
        subject.submit!
        subject.allocate!
        subject.assessment.update(fees: 100.00, expenses: 23.45)
        subject.authorise_part!
      }

      it { expect{ subject.redetermine! }.to change{ subject.state }.to('redetermination') }

      it { expect{ subject.await_written_reasons! }.to change{ subject.state }.to('awaiting_written_reasons') }

      it { expect{ subject.archive_pending_delete! }.to change{ subject.state }.to('archived_pending_delete') }
    end

    describe 'from refused' do
      before { subject.submit!; subject.allocate!; subject.refuse! }

      it { expect{ subject.redetermine! }.to change{ subject.state }.to('redetermination') }

      it { expect{ subject.await_written_reasons! }.to change{ subject.state }.to('awaiting_written_reasons') }

      it { expect{ subject.archive_pending_delete! }.to change{ subject.state }.to('archived_pending_delete') }
    end

    describe 'from rejected' do
      before { subject.submit!; subject.allocate!; subject.reject! }

      it { expect{ subject.archive_pending_delete! }.to change{ subject.state }.to('archived_pending_delete') }
    end

    describe 'from submitted' do
      before { subject.submit! }

      it { expect{ subject.allocate! }.to change{ subject.state }.to('allocated') }

      it { expect{ subject.archive_pending_delete! }.to raise_error(StateMachines::InvalidTransition) }

      describe 'when a claim exists with a, legacy, now non-valid evidence provision fee' do
        let(:claim) { create :litigator_claim, force_validation: true }
        let(:fee) { build :misc_fee, claim: claim, amount: '123', fee_type: fee_type }
        let(:fee_type) { build :misc_fee_type, :mievi }

        it { expect{ subject.allocate! }.not_to raise_error }
      end
    end

    describe "Allocated claim" do
      let(:claim) { create(:allocated_claim) }

      it "has a blank assessment" do
        expect(claim.assessment).not_to eq(nil)
        expect(claim.assessment.fees).to eq(0)
        expect(claim.assessment.expenses).to eq(0)
        expect(claim.assessment.disbursements).to eq(0)
      end

      context "updating assessment" do
        context "without updating the status" do
          let(:params) do
            {
              "assessment_attributes" => {
                "fees" => "1.00",
                "expenses" => "0.00",
                "vat_amount" => "0.00",
                "id" => claim.assessment.id
              }
            }
          end

          it "does not update the assessment" do
            claim.update_model_and_transition_state(params) rescue nil
            expect(claim.reload.assessment.fees).to eq(0)
          end
        end
      end
    end

    describe 'when supplier number has been invalidated' do
      let(:claim) { create(:litigator_claim, :fixed_fee, force_validation: true, fixed_fee: build(:fixed_fee, :lgfs)) }

      before { SupplierNumber.find_by(supplier_number: claim.supplier_number).delete }

      it { expect{ claim.submit! }.not_to raise_error }
    end
  end # describe 'valid transitions'

  describe 'set triggers' do
    before { Timecop.freeze(Time.now) }
    after  { Timecop.return }

    describe 'make archive_pending_delete valid for 180 days' do
      subject { create(:authorised_claim) }

      it {
        frozen_time = Time.now
        Timecop.freeze(frozen_time) { subject.archive_pending_delete! }

        expect(subject.valid_until).to eq(frozen_time + 180.days)
      }
    end

    describe 'make last_submitted_at attribute equal now' do
      it 'sets the last_submitted_at to the current time' do
        current_time = Time.now
        subject.submit!
        expect(subject.last_submitted_at).to eq(current_time)
      end

      it 'sets the original_submission_date to the current time' do
        current_time = Time.now
        subject.submit!
        expect(subject.original_submission_date).to eq(current_time)
      end
    end

    describe 'update last_submitted_at on redetermination or await_written_reasons' do
      it 'set the last_submitted_at to the current time for redetermination' do
        current_time = Time.now
        subject.submit!
        subject.allocate!
        subject.refuse!

        Timecop.freeze 6.months.from_now do
          subject.redetermine!
          expect(subject.last_submitted_at).to eq(current_time + 6.months)
        end
      end

      it 'set the last_submitted_at to the current time for awaiting_written_reasons' do
        current_time = Time.now
        subject.submit!
        subject.allocate!
        subject.refuse!

        Timecop.freeze 6.months.from_now do
          subject.await_written_reasons!
          expect(subject.last_submitted_at).to eq(current_time + 6.months)
        end
      end
    end

    describe 'authorise! makes authorised_at attribute equal now' do
      before { subject.submit!; subject.allocate! }

      it {
        subject.assessment.update(fees: 100.00, expenses: 23.45)

        frozen_time = Time.now + 1.month
        Timecop.freeze(frozen_time) { subject.authorise! }

        expect(subject.authorised_at).to eq(frozen_time)
      }
    end

    describe 'authorise_part! makes authorised_at attribute equal now' do
      before { subject.submit!; subject.allocate! }

      it {
        subject.assessment.update(fees: 100.00, expenses: 23.45)

        frozen_time = Time.now + 1.month
        Timecop.freeze(frozen_time) { subject.authorise_part! }

        expect(subject.authorised_at).to eq(frozen_time)
      }
    end
  end # describe 'set triggers'

  describe '.is_in_state?' do
    let(:claim)         { build :unpersisted_claim }

    it 'should be true if state is in EXTERNAL_USER_DASHBOARD_SUBMITTED_STATES' do
      allow(claim).to receive(:state).and_return('allocated')
      expect(Claims::StateMachine.is_in_state?(:external_user_dashboard_submitted?, claim)).to be true
    end

    it 'should return false if the state is not one of the EXTERNAL_USER_DASHBOARD_SUBMITTED_STATES' do
      allow(claim).to receive(:state).and_return('draft')
      expect(Claims::StateMachine.is_in_state?(:external_user_dashboard_submitted?, claim)).to be false
    end

    it 'should return false if the method name is not recognised' do
      allow(claim).to receive(:state).and_return('draft')
      expect(Claims::StateMachine.is_in_state?(:external_user_rubbish_submitted?, claim)).to be false
    end
  end

  describe 'state transition audit trail' do
    let!(:claim) { create(:advocate_claim) }
    let!(:expected) do
      {
        event: 'submit',
        from: 'draft',
        to: 'submitted',
        reason_code: []
      }
    end

    it 'should log state transitions' do
      expect { claim.submit! }.to change(ClaimStateTransition, :count).by(1)
    end

    it 'the log transition should reflect the state transition/change' do
      claim.submit!
      expect(ClaimStateTransition.last.event).to eq(expected[:event])
      expect(ClaimStateTransition.last.from).to eq(expected[:from])
      expect(ClaimStateTransition.last.to).to eq(expected[:to])
      expect(ClaimStateTransition.last.reason_code).to eq(expected[:reason_code])
    end
  end

  describe 'before submit state transition' do
    it 'sets the allocation_type for trasfer_claims' do
      claim = build(:transfer_claim, transfer_fee: build(:transfer_fee))
      expect(claim.allocation_type).to be nil
      claim.submit!
      expect(claim.allocation_type).to eq 'Grad'
    end
  end

  describe 'reject!' do
    before { claim.submit!; claim.allocate!; claim.reject!(reason_code: reason_codes) }
    let(:reason_codes) { ['no_indictment'] }
    let(:last_state_transition) { claim.last_state_transition }

    context 'claim state transitions (audit trail)' do
      it 'updates #to' do
        expect(last_state_transition.to).to eq('rejected')
      end

      it 'updates #reason_code[s]' do
        expect(last_state_transition.reason_codes).to eq(reason_codes)
      end
    end
  end

  describe 'refuse!' do
    let(:reason_codes) { ['wrong_ia'] }

    context 'when refused on first assessment' do

      before do
        subject.submit!
        subject.allocate!
      end

      context 'claim state transitions (audit trail)' do
        it 'updates #to' do
          expect { subject.refuse!(reason_code: reason_codes) }
            .to change { claim.reload.last_state_transition.to }
            .to 'refused'
        end

        it 'updates #reason_code[s]' do
          expect{ subject.refuse!(reason_code: reason_codes) }
            .to change{ subject.last_state_transition.reason_codes }
            .to(reason_codes)
        end

        it {expect{ subject.refuse!(reason_code: reason_codes) }.not_to change{ subject.assessment.fees }.from(0) }

        context 'test' do
          before { subject.refuse!(reason_code: reason_codes) }

          it { expect(subject.assessment.fees).to eq(0) }
        end
      end
    end

    context 'when refused on a redetermination' do
      before do
        claim.submit!
        claim.allocate!
        claim.assessment.update(fees: 123.00, expenses: 23.45)
        claim.authorise_part!
        claim.redetermine!
        claim.allocate!
      end

      it 'does not set the assessment to zero' do
        expect { claim.refuse!(reason_code: reason_codes) }
          .not_to change { claim.assessment.fees.to_f }
          .from(123.0)
      end
    end
  end

  describe '.set_allocation_type' do
    it 'calls the class method' do
      claim = build :transfer_claim
      claim.__send__(:set_allocation_type)
    end
  end
end
