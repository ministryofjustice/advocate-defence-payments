# frozen_string_literal: true

RSpec.describe 'Geckoboard statistics', type: :request, allow_forgery_protection: true do
  describe 'GET #index' do
    before { get statistics_path }

    let(:expected_reports) do
      { 'Claim creation by source' => 'claim_creation_source',
        'Claim Submissions' => 'claim_submissions',
        'Requests for further info' => 'requests_for_further_info',
        'Multi session submissions' => 'multi_session_submissions',
        'Time reject to auth' => 'time_reject_to_auth',
        'Completion rate' => 'completion_rate',
        'Time to completion' => 'time_to_completion',
        'Redeterminations average' => 'redeterminations_average',
        'Money claimed per month' => 'money_claimed_per_month' }
    end

    specify { expect(response).to render_template(:index) }
    specify { expect(assigns(:available_reports)).to match(expected_reports) }

    it_behaves_like 'a disabler of view only actions'
  end
end
