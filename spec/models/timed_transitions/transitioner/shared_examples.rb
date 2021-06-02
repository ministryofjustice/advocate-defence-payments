RSpec.shared_examples 'write transitioner log' do
  let(:succeeded) { true }
  let(:log_level) { :info }

  it 'writes to the log file' do
    allow(LogStuff).to receive(log_level)

    transitioner.run

    # TODO: Possibly include action, claim_id, claim_state, softly_deleted_on, valid_until, dummy_run and error in
    #       the list of parameters
    expect(LogStuff).to have_received(log_level)
      .with('TimedTransitions::Transitioner', hash_including(succeeded: succeeded))
  end
end

RSpec.shared_examples 'not write transitioner log' do
  let(:succeeded) { true }
  let(:log_level) { :info }

  it 'does not write to the log file' do
    allow(LogStuff).to receive(log_level)

    transitioner.run

    expect(LogStuff).not_to have_received(log_level)
  end
end

RSpec.shared_examples 'transitioning to archived pending delete' do
  subject(:transitioner) { described_class.new(claim) }

  context 'when last state transition less than 16 weeks ago' do
    before do
      travel_to 15.weeks.ago do
        claim
      end
    end

    it { expect { transitioner.run }.not_to change(claim, :state) }
  end

  context 'when last state change more than 16 weeks ago' do
    before do
      travel_to 17.weeks.ago do
        claim
      end
    end

    it { expect { transitioner.run }.to change(transitioner, :success?).to true }
    it { expect { transitioner.run }.to change(claim, :state).to 'archived_pending_delete' }

    it_behaves_like 'write transitioner log'

    it 'records the transition in claim state transitions' do
      transitioner.run
      expect(claim.reload.claim_state_transitions.first.reason_code).to eq(['timed_transition'])
    end

    context 'when claim validation fails' do
      before do
        claim.errors.add(:base, 'My mocked invalid state transition error message')
        allow(claim).to receive(:archive_pending_delete!)
                          .with(reason_code: ['timed_transition'])
                          .and_raise invalid_transition
      end

      let(:invalid_transition) do
        machine = StateMachines::Machine.find_or_create(claim.class)
        StateMachines::InvalidTransition.new(claim, machine, :archive_pending_delete)
      end

      it { expect { transitioner.run }.not_to raise_error }

      it_behaves_like 'write transitioner log' do
        let(:succeeded) { false }
        let(:log_level) { :error }
      end
    end

    # Not entirely sure what this is trying to prove.
    # Comment from previous version was 'not convinced actual tests are picking up claim error scenarios'
    context 'when the claim has been invalidated' do
      before { claim.update_attribute(:creator, create(:external_user, :litigator)) }

      it { expect { transitioner.run }.to change(claim, :state).to 'archived_pending_delete' }
    end

    # not convinced these tests are picking up claim error scenarios
    # trying to duplicate sentry error caused by
    # "StateMachines::InvalidTransition: Cannot transition state
    # via :archive_pending_delete from :authorised (Reason(s): Defendant 1
    # representation order 1 maat reference invalid)"
    context 'when a claim submodel has been invalidated' do
      before { claim.defendants.first.representation_orders.first.update_attribute(:maat_reference, '999') }

      it { expect { transitioner.run }.to change(claim, :state).to 'archived_pending_delete' }
    end
  end
end

RSpec.shared_examples 'transitioning to archived pending delete (dummy)' do
  context 'when last state transition less than 16 weeks ago' do
    subject(:transitioner) { described_class.new(claim, true) }

    before do
      travel_to(15.weeks.ago) do
        claim
      end
    end

    it { expect { transitioner.run }.not_to change(claim, :state) }

    it_behaves_like 'not write transitioner log' do
      let(:log_level) { :debug }
    end
  end

  context 'when last state transition more than 16 weeks ago' do
    subject(:transitioner) { described_class.new(claim, true) }

    before do
      travel_to(17.weeks.ago) do
        claim
      end
    end

    it { expect { transitioner }.not_to change(claim, :state) }

    it_behaves_like 'write transitioner log' do
      let(:succeeded) { false }
      let(:log_level) { :debug }
    end

    it 'does not record a timed_transition in claim state transitions' do
      transitioner.run
      expect(claim.claim_state_transitions.map(&:reason_code)).not_to include('timed_transition')
    end
  end
end

RSpec.shared_examples 'transitioning to archived pending review' do |initial_state|
  subject(:transitioner) { described_class.new(claim) }

  context 'when last state change more than 16 weeks ago' do
    before do
      travel_to 17.weeks.ago do
        claim
      end
    end

    context 'when the case type is a Hardship claim' do
      it { expect { transitioner.run }.to change(claim, :state).to 'archived_pending_review' }
    end
  end
end

RSpec.shared_examples 'transitioning to destroyed' do
  subject(:transitioner) { described_class.new(claim) }

  context 'when last state transition less than 16 weeks ago' do
    before do
      travel_to 15.weeks.ago do
        claim
      end
    end

    it { expect { transitioner.run }.not_to change(Claim::BaseClaim, :count) }

    it 'does not call destroy' do
      allow(transitioner).to receive(:destroy_claim)

      transitioner.run

      expect(transitioner).not_to have_received(:destroy_claim)
    end
  end

  context 'when last state transition more than 16 weeks ago' do
    before do
      travel_to(17.weeks.ago) do
        2.times { claim.expenses << Expense.new }
      end
    end

    # TODO: This is (similar to) the original test ...
    it { expect { transitioner.run }.to change(Claim::BaseClaim.where(id: claim.id), :count).to 0 }
    # TODO: ... but this is probably enough
    it { expect { transitioner.run }.to change(Claim::BaseClaim, :count).by -1 }

    it { expect { transitioner.run }.to change(Fee::BaseFee, :count).by -1 }
    it { expect { transitioner.run }.to change(Expense, :count).by -2 }
    it { expect { transitioner.run }.to change(Defendant.where(id: claim.id), :count).to 0 }
    # This depends on the configuration of the factory
    it { expect { transitioner.run }.to change(RepresentationOrder, :count).by -2 }
    # it { expect { transitioner.run }.to change(ClaimStateTransition.where(id: claim.id), :count).to 0 }
    it { expect { transitioner.run }.to change(Determination.where(id: claim.id), :count).to 0 }

    context 'with a date attended' do
      before { claim.expenses.first.dates_attended << DateAttended.new }

      it { expect { transitioner.run }.to change(DateAttended, :count).by -1 }
    end

    context 'with disbursements' do
      before { 2.times { claim.disbursements << create(:disbursement, claim: claim) } }

      it { expect { transitioner.run }.to change(Disbursement, :count).by -2 }
    end

    context 'with messages' do
      before { 2.times { claim.messages << create(:message, claim: claim) } }

      it { expect { transitioner.run }.to change(Message, :count).by -2 }
    end

    context 'with certification' do
      before { claim.certification = create(:certification, claim: claim) }

      it { expect { transitioner.run }.to change(Certification, :count).by -1 }
    end

    context 'with injection attempts' do
      before { claim.injection_attempts << create(:injection_attempt, claim: claim) }

      it { expect { transitioner.run }.to change(InjectionAttempt, :count).by -1 }
    end

    context 'with an associated document' do
      let(:file) do
        let(:document) { create :document, verified: true }

        before { claim.update(documents: [document]) }

        it 'destroys associated documents' do
          expect { run_transitioner }.to change(Document, :count).by(-1)
        end

        it 'deletes the file from storage' do
          file_on_disk = ActiveStorage::Blob.service.send(:path_for, claim.documents.first.document.blob.key)

          expect { run_transitioner }.to change { File.exist? file_on_disk }.from(true).to false
        end
      end
    end

    it_behaves_like 'write transitioner log'
  end
end

# context 'when destroying' do
#   context 'when claim softly-deleted more than 16 weeks ago' do
#     let(:claim) { create :archived_pending_delete_claim }
#
#     it 'destroys the claim' do
#       expect(claim).to receive(:softly_deleted?).and_return(true)
#       expect(claim).to receive(:destroy)
#       described_class.new(claim).run
#     end
#
#     it 'creates an MI version of the record' do
#       expect(claim).to receive(:softly_deleted?).and_return(true)
#       expect(claim).to receive(:destroy)
#       expect { described_class.new(claim).run }.to change { Stats::MIData.count }.by 1
#     end
#
#     context 'for hardship claims' do
#       let(:claim) { create :advocate_hardship_claim }
#
#       context 'when claim softly-deleted 17 weeks ago' do
#         before { travel_to(17.weeks.ago) { claim.soft_delete } }
#
#         it 'deletes the application' do
#           expect(claim).to receive(:destroy)
#           expect { described_class.new(claim).run }.to change { Stats::MIData.count }.by 1
#         end
#       end
#     end
#   end
#
#   context 'when last state transition more than 16 weeks ago' do
#     subject(:run_transitioner) { described_class.new(claim).run }
#
#     let(:claim) do
#       travel_to(17.weeks.ago) do
#         create :litigator_claim, :archived_pending_delete, case_number: 'A20164444'
#       end
#     end
#
#     after(:all) { clean_database }
#
#     it 'destroys the claims' do
#       run_transitioner
#       expect(Claim::BaseClaim.where(id: claim.id)).to be_empty
#     end
#
#     # TODO: This tests that various associated records are deleted when the claim is deleted. To avoid confusion
#     #       these should be split up into separate tests.
#     context 'with test associations' do
#       before do
#         claim.defendants.first.representation_orders << RepresentationOrder.new
#         2.times { claim.expenses << Expense.new }
#         2.times { claim.disbursements << create(:disbursement, claim: claim) }
#         2.times { claim.messages << create(:message, claim: claim) }
#         claim.injection_attempts << create(:injection_attempt, claim: claim)
#         claim.expenses.first.dates_attended << DateAttended.new
#         claim.certification = create(:certification, claim: claim)
#         claim.save!
#         claim.reload
#
#         @first_expense_id = claim.expenses.first.id
#         @first_defendant_id = claim.defendants.first.id
#       end
#
#       it 'destroys all associated records', delete: true do
#         check_associations
#         described_class.new(claim).run
#         expect_claim_and_all_associations_to_be_gone
#       end
#     end
#
#     context 'with an associated document' do
#       let(:file) do
#         let(:document) { create :document, verified: true }
#
#         before { claim.update(documents: [document]) }
#
#         it 'destroys associated documents' do
#           expect { run_transitioner }.to change(Document, :count).by(-1)
#         end
#
#         it 'deletes the file from storage' do
#           file_on_disk = ActiveStorage::Blob.service.send(:path_for, claim.documents.first.document.blob.key)
#
#           expect { run_transitioner }.to change { File.exist? file_on_disk }.from(true).to false
#         end
#       end
#     end
#
#     it 'writes to the log file' do
#       expect(LogStuff).to receive(:info)
#                             .with('TimedTransitions::Transitioner',
#                                   action: 'destroy',
#                                   claim_id: claim.id,
#                                   claim_state: 'archived_pending_delete',
#                                   softly_deleted_on: claim.deleted_at,
#                                   valid_until: claim.valid_until,
#                                   dummy_run: false,
#                                   error: nil,
#                                   succeeded: true)
#       described_class.new(claim).run
#     end
#
#     def check_associations
#       expect(claim.case_worker_claims).not_to be_empty
#       expect(claim.case_workers).not_to be_empty
#       expect(claim.fees).not_to be_empty
#       expect(claim.expenses).not_to be_empty
#       expect(claim.expenses.first.dates_attended).not_to be_empty
#       expect(claim.disbursements).not_to be_empty
#       expect(claim.defendants).not_to be_empty
#       expect(claim.defendants.first.representation_orders).not_to be_empty
#       expect(claim.messages).not_to be_empty
#       expect(claim.claim_state_transitions).not_to be_empty
#       expect(claim.determinations).not_to be_empty
#       expect(claim.certification).not_to be_nil
#       expect(claim.injection_attempts).not_to be_empty
#     end
#
#     def expect_claim_and_all_associations_to_be_gone
#       expect { Claim::BaseClaim.find(claim.id) }.to raise_error ActiveRecord::RecordNotFound, "Couldn't find Claim::BaseClaim with 'id'=#{claim.id}"
#       expect(CaseWorkerClaim.where(claim_id: claim.id)).to be_empty
#       expect(Fee::BaseFee.where(claim_id: claim.id)).to be_empty
#       expect(Expense.where(claim_id: claim.id)).to be_empty
#       expect(DateAttended.where(attended_item_id: @first_expense_id, attended_item_type: 'Expense')).to be_empty
#       expect(Disbursement.where(claim_id: claim.id)).to be_empty
#       expect(Defendant.where(claim_id: claim.id)).to be_empty
#       expect(RepresentationOrder.where(defendant_id: @first_defendant_id)).to be_empty
#       expect(Message.where(claim_id: claim.id)).to be_empty
#       expect(ClaimStateTransition.where(claim_id: claim.id)).to be_empty
#       expect(Determination.where(claim_id: claim.id)).to be_empty
#       expect(Certification.where(claim_id: claim.id)).to be_empty
#       expect(InjectionAttempt.where(claim_id: claim.id)).to be_empty
#     end
#   end
# end
