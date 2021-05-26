require 'rails_helper'

RSpec.describe TimedTransitions::Transitioner do
  let(:claim) { double Claim }

  describe '.candidate_states' do
    subject { described_class.candidate_states }

    it 'returns an array of source states for timed transitions' do
      is_expected.to eq %i[
        draft
        authorised
        part_authorised
        refused
        rejected
        archived_pending_delete
      ]
    end
  end

  describe '.candidate_claims_ids' do
    subject { described_class.candidate_claims_ids }

    it 'returns a list of ids in the target states' do
      draft_claim = authorised_claim = archived_claim = part_authorised_claim = refused_claim = rejected_claim = agfs_hardship_claim = nil

      travel_to(18.weeks.ago) do
        draft_claim = create :advocate_claim
        create :submitted_claim
        create :allocated_claim
        authorised_claim = create :authorised_claim
        archived_claim = create :archived_pending_delete_claim
        create :redetermination_claim
        part_authorised_claim = create :part_authorised_claim
        refused_claim = create :refused_claim
        rejected_claim = create :rejected_claim
        agfs_hardship_claim = create :advocate_hardship_claim
      end

      # This claim will not meet the time scope
      create :advocate_claim

      expected_ids = [draft_claim.id, authorised_claim.id, archived_claim.id, part_authorised_claim.id, refused_claim.id, rejected_claim.id, agfs_hardship_claim.id].sort
      is_expected.to match_array(expected_ids)
    end
  end

  describe '.softly_deleted_ids' do
    subject { described_class.softly_deleted_ids }

    it 'returns ids of claims that were softly deleted more than 16 weeks ago' do
      claim_a = claim_b = claim_c = claim_hs = nil
      travel_to(18.weeks.ago) do
        claim_a, claim_b, claim_c = create_list(:advocate_claim, 3)
        claim_hs = create :advocate_hardship_claim
      end
      travel_to(17.weeks.ago) { claim_a.soft_delete }
      travel_to(17.weeks.ago) { claim_hs.soft_delete }
      travel_to(15.weeks.ago) { claim_b.soft_delete }
      is_expected.not_to include(claim_c.id)
      is_expected.not_to include(claim_b.id)
      is_expected.to include(claim_a.id)
      is_expected.to include(claim_hs.id)
    end
  end

  describe '.create' do
    subject { described_class.create(claim) }

    context 'with an authorised claim' do
      let(:claim) { create :authorised_claim }

      it { is_expected.to be_a TimedTransitions::Transitioner::Archive }
    end

    context 'with a part authorised claim' do
      let(:claim) { create :part_authorised_claim }

      it { is_expected.to be_a TimedTransitions::Transitioner::Archive }
    end

    context 'with a refused claim' do
      let(:claim) { create :refused_claim }

      it { is_expected.to be_a TimedTransitions::Transitioner::Archive }
    end

    context 'with a rejected claim' do
      let(:claim) { create :rejected_claim }

      it { is_expected.to be_a TimedTransitions::Transitioner::Archive }
    end

    context 'with a draft claim' do
      let(:claim) { create :draft_claim }

      it { is_expected.to be_a TimedTransitions::Transitioner::Delete }
    end

    context 'with an archived pending delete claim' do
      let(:claim) { create :archived_pending_delete_claim }

      it { is_expected.to be_a TimedTransitions::Transitioner::Delete }
    end

    context 'with an allocated claim' do
      let(:claim) { create :allocated_claim }

      it { is_expected.to be_a TimedTransitions::Transitioner::Null }
    end
  end

  describe '#run' do
    context 'with non-dummy run' do
      context 'when destroying' do
        context 'when claim softly-deleted more than 16 weeks ago' do
          let(:claim) { create :archived_pending_delete_claim }

          it 'destroys the claim' do
            expect(claim).to receive(:softly_deleted?).and_return(true)
            expect(claim).to receive(:destroy)
            described_class.new(claim).run
          end

          it 'creates an MI version of the record' do
            expect(claim).to receive(:softly_deleted?).and_return(true)
            expect(claim).to receive(:destroy)
            expect { described_class.new(claim).run }.to change { Stats::MIData.count }.by 1
          end

          context 'for hardship claims' do
            let(:claim) { create :advocate_hardship_claim }

            context 'when claim softly-deleted 17 weeks ago' do
              before { travel_to(17.weeks.ago) { claim.soft_delete } }

              it 'deletes the application' do
                expect(claim).to receive(:destroy)
                expect { described_class.new(claim).run }.to change { Stats::MIData.count }.by 1
              end
            end
          end
        end

        context 'when last state transition less than 16 weeks ago' do
          subject(:transitioner) { described_class.new(claim) }
          let(:claim) { double Claim }

          before do
            allow(claim).to receive(:last_state_transition_time).at_least(:once).and_return(15.weeks.ago)
            allow(claim).to receive(:state).and_return('archived_pending_delete')
            allow(claim).to receive(:softly_deleted?).and_return(false)
          end

          it 'does not call destroy' do
            expect(transitioner).not_to receive(:destroy_claim)
            transitioner.run
          end
        end

        context 'when last state transition more than 16 weeks ago' do
          subject(:run_transitioner) { described_class.new(claim).run }

          let(:claim) do
            travel_to(17.weeks.ago) do
              create :litigator_claim, :archived_pending_delete, case_number: 'A20164444'
            end
          end

          after(:all) { clean_database }

          it 'destroys the claims' do
            run_transitioner
            expect(Claim::BaseClaim.where(id: claim.id)).to be_empty
          end

          # TODO: This tests that various associated records are deleted when the claim is deleted. To avoid confusion
          #       these should be split up into separate tests.
          context 'with test associations' do
            before do
              claim.defendants.first.representation_orders << RepresentationOrder.new
              2.times { claim.expenses << Expense.new }
              2.times { claim.disbursements << create(:disbursement, claim: claim) }
              2.times { claim.messages << create(:message, claim: claim) }
              claim.injection_attempts << create(:injection_attempt, claim: claim)
              claim.expenses.first.dates_attended << DateAttended.new
              claim.certification = create(:certification, claim: claim)
              claim.save!
              claim.reload

              @first_expense_id = claim.expenses.first.id
              @first_defendant_id = claim.defendants.first.id
            end

            it 'destroys all associated records', delete: true do
              check_associations
              described_class.new(claim).run
              expect_claim_and_all_associations_to_be_gone
            end
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

          it 'writes to the log file' do
            expect(LogStuff).to receive(:info)
              .with('TimedTransitions::Transitioner',
                    action: 'destroy',
                    claim_id: claim.id,
                    claim_state: 'archived_pending_delete',
                    softly_deleted_on: claim.deleted_at,
                    valid_until: claim.valid_until,
                    dummy_run: false,
                    error: nil,
                    succeeded: true)
            described_class.new(claim).run
          end

          def check_associations
            expect(claim.case_worker_claims).not_to be_empty
            expect(claim.case_workers).not_to be_empty
            expect(claim.fees).not_to be_empty
            expect(claim.expenses).not_to be_empty
            expect(claim.expenses.first.dates_attended).not_to be_empty
            expect(claim.disbursements).not_to be_empty
            expect(claim.defendants).not_to be_empty
            expect(claim.defendants.first.representation_orders).not_to be_empty
            expect(claim.messages).not_to be_empty
            expect(claim.claim_state_transitions).not_to be_empty
            expect(claim.determinations).not_to be_empty
            expect(claim.certification).not_to be_nil
            expect(claim.injection_attempts).not_to be_empty
          end

          def expect_claim_and_all_associations_to_be_gone
            expect { Claim::BaseClaim.find(claim.id) }.to raise_error ActiveRecord::RecordNotFound, "Couldn't find Claim::BaseClaim with 'id'=#{claim.id}"
            expect(CaseWorkerClaim.where(claim_id: claim.id)).to be_empty
            expect(Fee::BaseFee.where(claim_id: claim.id)).to be_empty
            expect(Expense.where(claim_id: claim.id)).to be_empty
            expect(DateAttended.where(attended_item_id: @first_expense_id, attended_item_type: 'Expense')).to be_empty
            expect(Disbursement.where(claim_id: claim.id)).to be_empty
            expect(Defendant.where(claim_id: claim.id)).to be_empty
            expect(RepresentationOrder.where(defendant_id: @first_defendant_id)).to be_empty
            expect(Message.where(claim_id: claim.id)).to be_empty
            expect(ClaimStateTransition.where(claim_id: claim.id)).to be_empty
            expect(Determination.where(claim_id: claim.id)).to be_empty
            expect(Certification.where(claim_id: claim.id)).to be_empty
            expect(InjectionAttempt.where(claim_id: claim.id)).to be_empty
          end
        end
      end
    end

    context 'with dummy run' do
      context 'when destroying' do
        context 'when last state transition less than 16 weeks ago' do
          subject(:transitioner) { described_class.new(claim, true) }
          let(:claim) { double Claim }

          before do
            allow(claim).to receive(:last_state_transition_time).at_least(:once).and_return(15.weeks.ago)
            allow(claim).to receive(:state).and_return('archived_pending_delete')
            allow(claim).to receive(:softly_deleted?).and_return(false)
          end

          it 'does not call archive on claim' do
            expect(transitioner).not_to receive(:destroy_claim)
            expect(LogStuff).not_to receive(:debug)
            transitioner.run
          end
        end

        context 'when last state transition more than 16 weeks ago' do
          subject(:run_transitioner) { described_class.new(claim, true).run }

          let(:claim) do
            travel_to(17.weeks.ago) do
              create :litigator_claim, :archived_pending_delete, case_number: 'A20164444'
            end
          end

          it 'does not destroy the claim' do
            described_class.new(claim, true).run
            expect(Claim::BaseClaim.where(id: claim.id)).not_to be_empty
          end

          # TODO: This tests that various associated records are not deleted when the claim is not deleted. This could
          # probably be deleted or, at least, split up into separate tests to avoid confusion.
          context 'with test associations' do
            before do
              claim.defendants.first.representation_orders << RepresentationOrder.new
              2.times { claim.expenses << Expense.new }
              2.times { claim.disbursements << create(:disbursement, claim: claim) }
              2.times { claim.messages << create(:message, claim: claim) }
              claim.expenses.first.dates_attended << DateAttended.new
              claim.documents << create(:document, claim: claim, verified: true)
              claim.certification = create(:certification, claim: claim)
              claim.save!
              claim.reload

              @first_expense_id = claim.expenses.first.id
              @first_defendant_id = claim.defendants.first.id
            end

            it 'does not destroy all associated records' do
              check_associations
              run_transitioner
              expect_claim_and_all_associations_to_be_present
            end
          end

          context 'with an associated document' do
            let(:document) { create :document, verified: true }

            before { claim.update(documents: [document]) }

            it 'does not destroy associated documents' do
              expect { run_transitioner }.not_to change(Document, :count)
            end

            it 'does not delete the file from storage' do
              file_on_disk = ActiveStorage::Blob.service.send(:path_for, claim.documents.first.document.blob.key)

              expect { run_transitioner }.not_to(change { File.exist? file_on_disk })
            end
          end

          it 'writes to the log file' do
            expect(LogStuff).to receive(:debug)
              .with(
                'TimedTransitions::Transitioner',
                action: 'destroy',
                claim_id: claim.id,
                claim_state: claim.state,
                softly_deleted_on: claim.deleted_at,
                valid_until: claim.valid_until,
                dummy_run: true,
                error: nil,
                succeeded: false
              )
            described_class.new(claim, true).run
          end

          def check_associations
            expect(claim.case_worker_claims).not_to be_empty
            expect(claim.case_workers).not_to be_empty
            expect(claim.fees).not_to be_empty
            expect(claim.expenses).not_to be_empty
            expect(claim.expenses.first.dates_attended).not_to be_empty
            expect(claim.disbursements).not_to be_empty
            expect(claim.defendants).not_to be_empty
            expect(claim.defendants.first.representation_orders).not_to be_empty
            expect(claim.messages).not_to be_empty
            expect(claim.claim_state_transitions).not_to be_empty
            expect(claim.determinations).not_to be_empty
            expect(claim.certification).not_to be_nil
          end

          def expect_claim_and_all_associations_to_be_present
            expect(Claim::BaseClaim.find(claim.id)).to eq claim
            expect(CaseWorkerClaim.where(claim_id: claim.id)).not_to be_empty
            expect(Fee::BaseFee.where(claim_id: claim.id)).not_to be_empty
            expect(Expense.where(claim_id: claim.id)).not_to be_empty
            expect(DateAttended.where(attended_item_id: @first_expense_id, attended_item_type: 'Expense')).not_to be_empty
            expect(Disbursement.where(claim_id: claim.id)).not_to be_empty
            expect(Defendant.where(claim_id: claim.id)).not_to be_empty
            expect(RepresentationOrder.where(defendant_id: @first_defendant_id)).not_to be_empty
            expect(Message.where(claim_id: claim.id)).not_to be_empty
            expect(ClaimStateTransition.where(claim_id: claim.id)).not_to be_empty
            expect(Determination.where(claim_id: claim.id)).not_to be_empty
            expect(Certification.where(claim_id: claim.id)).not_to be_empty
          end
        end
      end
    end
  end
end
