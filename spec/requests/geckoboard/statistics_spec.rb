# frozen_string_literal: true

RSpec.shared_examples 'a disabler of view only actions' do
  it { expect(assigns(:disable_analytics)).to be_truthy }
  it { expect(assigns(:disable_phase_banner)).to be_truthy }
  it { expect(assigns(:disable_flashes)).to be_truthy }
end

RSpec.describe 'Geckoboard statistics', type: :request do
  describe 'GET #index' do
    before { get statistics_path }

    let(:expected_reports) { { 'Claim creation by source' => 'claim_creation_source',
                               'Claim Submissions' => 'claim_submissions',
                               'Requests for further info' => 'requests_for_further_info',
                               'Multi session submissions' => 'multi_session_submissions',
                               'Time reject to auth' => 'time_reject_to_auth',
                               'Completion rate' => 'completion_rate',
                               'Time to completion' => 'time_to_completion',
                               'Redeterminations average' => 'redeterminations_average',
                               'Money claimed per month' => 'money_claimed_per_month' } }

    it { expect(response).to render_template(:index) }
    it { expect(assigns(:available_reports)).to match(expected_reports) }
    it_behaves_like 'a disabler of view only actions'
  end
end
