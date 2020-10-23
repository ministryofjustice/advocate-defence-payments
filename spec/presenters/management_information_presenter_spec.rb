require 'rails_helper'

RSpec.describe ManagementInformationPresenter do

  let(:claim) { create(:redetermination_claim) }
  let(:presenter) { ManagementInformationPresenter.new(claim, view) }
  let(:previous_user) { create(:user, first_name: 'Thea', last_name: 'Conway') }
  let(:another_user) { create(:user, first_name: 'Hilda', last_name: 'Rogers') }


  context '#present!' do

    context 'generates a line of CSV for each time a claim passes through the system' do

      context 'with identical values for' do

        it 'case_number' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include(claim.case_number)
            expect(claim_journeys.second).to include(claim.case_number)
          end
        end

        it 'supplier number' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include(claim.supplier_number)
            expect(claim_journeys.second).to include(claim.supplier_number)
          end
        end

        it 'organisation/provider_name' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include(claim.external_user.provider.name)
            expect(claim_journeys.second).to include(claim.external_user.provider.name)
          end
        end

        it 'case_type' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include(claim.case_type.name)
            expect(claim_journeys.second).to include(claim.case_type.name)
          end
        end

        context 'AGFS' do
          it 'scheme' do
            presenter.update_column(:type, 'Claim::AdvocateInterimClaim')

            presenter.present! do |claim_journeys|
              expect(claim_journeys.first).to include('AGFS')
              expect(claim_journeys.second).to include('AGFS')
            end
          end

          it 'bill_type' do
            presenter.update_column(:type, 'Claim::AdvocateInterimClaim')

            presenter.present! do |claim_journeys|
              expect(claim_journeys.first).to include('AGFS Interim')
              expect(claim_journeys.second).to include('AGFS Interim')
            end
          end
        end

        context 'LGFS' do
          let(:claim) { create(:litigator_claim, :redetermination) }

          it 'scheme' do
            presenter.update_column(:type, 'Claim::LitigatorClaim')

            presenter.present! do |claim_journeys|
              expect(claim_journeys.first).to include('LGFS')
              expect(claim_journeys.second).to include('LGFS')
            end
          end

          it 'bill_type' do
            presenter.update_column(:type, 'Claim::LitigatorHardshipClaim')

            presenter.present! do |claim_journeys|
              expect(claim_journeys.first).to include('LGFS Hardship')
              expect(claim_journeys.second).to include('LGFS Hardship')
            end
          end
        end

        it 'total (inc VAT)' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include(claim.total_including_vat.to_s)
            expect(claim_journeys.second).to include(claim.total_including_vat.to_s)
          end
        end

        it 'disc evidence' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include('No')
            expect(claim_journeys.second).to include('No')
          end
        end
      end

      describe 'disc evidence' do
        subject { presenter.disk_evidence_case }

        context 'when the applicant has checked disc_evidence' do
          let(:claim) { create :advocate_claim, disk_evidence: true }

          it { is_expected.to eq 'Yes' }
        end

        context 'when the applicant has not checked disc_evidence' do
          let(:claim) { create :advocate_claim }

          it { is_expected.to eq 'No' }
        end
      end

      describe 'main_defendant' do
        subject { presenter.main_defendant }

        it { is_expected.to eq claim.defendants.first.name }
      end

      describe 'maat_reference' do
        subject { presenter.maat_reference }

        it { is_expected.to eq claim.earliest_representation_order.maat_reference }
      end

      describe 'rep_order_issued_date' do
        subject { presenter.rep_order_issued_date }

        it { is_expected.to eq claim.earliest_representation_order&.representation_order_date&.strftime('%d/%m/%Y') }
      end

      describe 'caseworker name' do
        context 'decision transition doesnt exist' do
          it 'returns nil' do
            draft_claim = create :advocate_claim
            expect(draft_claim.last_decision_transition).to be_nil
            presenter = ManagementInformationPresenter.new(claim, view)
            expect(presenter.case_worker).to be_nil
          end
        end

        context 'author_id on the decision transition is nil' do
          it 'returns nil' do
            transition = claim.last_decision_transition
            transition.update_author_id(nil)
            presenter = ManagementInformationPresenter.new(claim, view)
            expect(presenter.case_worker).to be_nil
          end
        end

        context 'a decided claim' do
          it 'returns name of the caseworker that made the decision' do
            authorised_claim = create :authorised_claim
            transition = authorised_claim.last_decision_transition
            case_worker_name = transition.author.name
            presenter = ManagementInformationPresenter.new(authorised_claim, view)
            expect(presenter.case_worker).to eq case_worker_name
          end
        end

        context 'an allocated claim' do
          it 'returns the name of the caseworker allocated to the claim' do
            allocated_claim = create :allocated_claim
            case_worker_name = allocated_claim.case_workers.first.name
            presenter = ManagementInformationPresenter.new(allocated_claim, view)
            expect(presenter.case_worker).to eq case_worker_name
          end
        end

      end

      # Case worker name isn't unique - might not be the user who was working on this case just before redetermination
      # What about when case is marked as redetermination multiple times?

      describe 'af1_lf1_processed_by' do
        context 'an allocated claim' do
          it 'returns nil' do
            claim = create :authorised_claim
            presenter = ManagementInformationPresenter.new(claim, view)
            presenter.present! do |claim_journeys|
              expect(presenter.af1_lf1_processed_by).to eq ''
            end
          end
        end

        context 'a redetermined claim' do
          it 'returns the name of the last caseworker to update before redetermination' do
            claim = create :authorised_claim
            transition = claim.last_decision_transition
            transition.update_author_id(previous_user.id)
            claim.redetermine!
            presenter = ManagementInformationPresenter.new(claim, view)
            presenter.present! do |claim_journeys|
              expect(presenter.af1_lf1_processed_by).to eq previous_user.name
            end
          end
        end

        context 'a claim that is redetermined twice' do
          it 'returns the name of the last caseworker to update before redetermination' do
            claim = create :redetermination_claim
            claim.allocate!
            claim.authorise!
            transition = claim.last_decision_transition
            transition.update_author_id(another_user.id)
            claim.redetermine!
            presenter = ManagementInformationPresenter.new(claim, view)
            presenter.present! do |claim_journeys|
              expect(presenter.af1_lf1_processed_by).to eq another_user.name
            end
          end
        end
      end

      describe 'misc_fees' do
        subject { presenter.misc_fees }

        it { is_expected.to eq claim.misc_fees.map{ |f| f.fee_type.description.tr(',', '')}.join(' ') }
      end

      describe '#transitioned_at' do
        it 'set per transition' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include((Time.zone.now - 3.day).strftime('%d/%m/%Y'))
            expect(claim_journeys.second).to include((Time.zone.now).strftime('%d/%m/%Y'))
          end
        end
      end

      describe '#last_submitted_at' do
        subject { presenter.last_submitted_at }

        let(:last_submitted_at) { Date.new(2017, 9, 20) }

        before do
          claim.last_submitted_at = last_submitted_at
        end

        it { is_expected.to eql last_submitted_at.strftime('%d/%m/%Y') }
      end

      describe '#originally_submitted_at' do
        subject { presenter.originally_submitted_at }

        let(:original_submission_date) { Date.new(2015, 6, 18) }

        before do
          claim.original_submission_date = original_submission_date
        end

        it { is_expected.to eql original_submission_date.strftime('%d/%m/%Y') }
      end

      context 'and unique values for' do
        before { Timecop.freeze(Time.now) }
        after  { Timecop.return }

        it 'submission type' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include('new')
            expect(claim_journeys.second).to include('redetermination')
          end
        end

        it 'date allocated' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include((Time.zone.now - 2.day).strftime('%d/%m/%Y'))
            expect(claim_journeys.second).to include('n/a', 'n/a')
          end
        end

        it 'date of last assessment' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include((Time.zone.now - 1.day).strftime('%d/%m/%Y %H:%M'))
            expect(claim_journeys.second).to include('n/a', 'n/a')
          end
        end

        it 'current/end state' do
          presenter.present! do |claim_journeys|
            expect(claim_journeys.first).to include('authorised')
            expect(claim_journeys.second).to include('submitted')
          end
        end
      end

      context 'deallocation' do
        let(:claim) { create(:allocated_claim) }

        before {
          case_worker = claim.case_workers.first
          claim.deallocate!
          claim.case_workers << case_worker
          claim.reload.deallocate!
        }

        it 'should not be reflected in the MI' do
          ManagementInformationPresenter.new(claim, view).present! do |csv|
            expect(csv[0]).not_to include('deallocated')
          end
        end

        it 'and the claim should be refelcted as being in the state prior to allocation' do
          ManagementInformationPresenter.new(claim, view).present! do |csv|
            expect(csv[0]).to include('submitted')
          end
        end
      end

      context 'archived_pending_delete' do
        let(:claim) { create(:archived_pending_delete_claim) }
       
        it 'adds a single row to the MI' do
          ManagementInformationPresenter.new(claim, view).present! do |csv|
            expect(csv.size).to eql 1
          end
        end

        it 'should not be reflected in the MI' do
          ManagementInformationPresenter.new(claim, view).present! do |csv|
            expect(csv[0]).not_to include('archived_pending_delete')
          end
        end

        it 'and the claim should be reflected as being in the state prior to archive' do
          ManagementInformationPresenter.new(claim, view).present! do |csv|
            expect(csv[0]).to include('authorised')
          end
        end
      end

      context 'archived_pending_review' do
        let(:claim) { create(:hardship_archived_pending_review_claim) }

        it 'adds a single row to the MI' do
          ManagementInformationPresenter.new(claim, view).present! do |csv|
            expect(csv.size).to eql 1
          end
        end
        
        it 'should not be reflected in the MI' do
          ManagementInformationPresenter.new(claim, view).present! do |csv|
            expect(csv[0]).not_to include('archived_pending_review')
          end
        end

        it 'and the claim should be reflected as being in the state prior to archive' do
          ManagementInformationPresenter.new(claim, view).present! do |csv|
            expect(csv[0]).to include('authorised')
          end
        end
      end


      context 'state transitions reasons' do
        let(:claim) { create(:allocated_claim) }
        let(:colidx) { 15 }

        context 'rejected with a single reason as a string ' do
          before do
            claim.reject!(reason_code: ['no_rep_order'])
          end

          it 'the rejection reason code should be reflected in the MI' do
            allow_any_instance_of(ClaimStateTransition).to receive(:reason_code).and_return('no_rep_order')
            ManagementInformationPresenter.new(claim, view).present! do |csv|
              expect(csv[0][colidx]).to eq('no_rep_order')
            end
          end
        end

        context 'rejected with a single reason' do
          before do
            claim.reject!(reason_code: ['no_rep_order'])
          end

          it 'the rejection reason code should be reflected in the MI' do
            ManagementInformationPresenter.new(claim, view).present! do |csv|
              expect(csv[0][colidx]).to eq('no_rep_order')
            end
          end
        end

        context 'rejected with a multiple reasons' do
          before do
            claim.reject!(reason_code: ['no_rep_order', 'wrong_case_no'])
          end

          it 'the rejection reason code should be reflected in the MI' do
            ManagementInformationPresenter.new(claim, view).present! do |csv|
              expect(csv[0][colidx]).to eq('no_rep_order, wrong_case_no')
            end
          end
        end

        context 'rejected with other' do
          before do
            claim.reject!(reason_code: ['other'], reason_text: 'Rejection reason')
          end

          it 'the rejection reason code should be reflected in the MI' do
            ManagementInformationPresenter.new(claim, view).present! do |csv|
              expect(csv[0][colidx]).to eq('other')
              expect(csv[0][colidx+1]).to eq('Rejection reason')
            end
          end
        end

        context 'refused with a single reason as a string ' do
          before do
            claim.refuse!(reason_code: ['no_rep_order'])
          end

          it 'the refusal reason code should be reflected in the MI' do
            allow_any_instance_of(ClaimStateTransition).to receive(:reason_code).and_return('no_rep_order')
            ManagementInformationPresenter.new(claim, view).present! do |csv|
              expect(csv[0][colidx]).to eq('no_rep_order')
            end
          end
        end

        context 'refused with a single reason' do
          before do
            claim.refuse!(reason_code: ['no_rep_order'])
          end

          it 'the refusal reason code should be reflected in the MI' do
            ManagementInformationPresenter.new(claim, view).present! do |csv|
              expect(csv[0][colidx]).to eq('no_rep_order')
            end
          end
        end

        context 'refused with multiple reasons' do
          before do
            claim.refuse!(reason_code: ['no_rep_order', 'wrong_case_no'])
          end

          it 'the refusal reason code should be reflected in the MI' do
            ManagementInformationPresenter.new(claim, view).present! do |csv|
              expect(csv[0][colidx]).to eq('no_rep_order, wrong_case_no')
            end
          end
        end

        context 'rejected with other' do
          before do
            claim.reject!(reason_code: ['other'], reason_text: 'Rejection reason')
          end

          it 'the rejection reason code should be reflected in the MI' do
            ManagementInformationPresenter.new(claim, view).present! do |csv|
              expect(csv[0][colidx]).to eq('other')
              expect(csv[0][colidx+1]).to eq('Rejection reason')
            end
          end
        end
      end
    end
  end
end
