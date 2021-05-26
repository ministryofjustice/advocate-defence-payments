require 'rails_helper'
require 'models/timed_transitions/transitioner/shared_examples'

RSpec.describe TimedTransitions::Transitioner::Archive do
  context 'with an authorised claim' do
    let(:claim) { create :authorised_claim }

    include_examples 'transitioning to archived pending delete'
    include_examples 'transitioning to archived pending delete (dummy)'
  end

  context 'with an authorised hardship claim' do
    let(:claim) { create :advocate_hardship_claim, :authorised }

    include_examples 'transitioning to archived pending review'
  end

  context 'with a part authorised claim' do
    let(:claim) { create :part_authorised_claim }

    include_examples 'transitioning to archived pending delete'
    include_examples 'transitioning to archived pending delete (dummy)'
  end

  context 'with a refused claim' do
    let(:claim) { create :refused_claim }

    include_examples 'transitioning to archived pending delete'
    include_examples 'transitioning to archived pending delete (dummy)'
  end

  context 'with a rejected claim' do
    let(:claim) { create :rejected_claim }

    include_examples 'transitioning to archived pending delete'
    include_examples 'transitioning to archived pending delete (dummy)'
  end

  context 'with a rejected hardship claim' do
    let(:claim) { create :advocate_hardship_claim, :rejected }

    include_examples 'transitioning to archived pending review'
  end
end
