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
