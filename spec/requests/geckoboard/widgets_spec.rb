# frozen_string_literal: true

RSpec.describe 'Widgets', type: :request, allow_forgery_protection: true do
  describe 'GET #claim_creation_source' do
    context 'with format html' do
      before { get claim_creation_source_geckoboard_api_widgets_path(format: :html) }

      it { expect(response).to render_template(:claim_creation_source) }
    end

    context 'with format json' do
      # rubocop:disable RSpec/AnyInstance
      before do
        allow_any_instance_of(Stats::BaseDataGenerator).to receive(:run).and_return(payload)
        get claim_creation_source_geckoboard_api_widgets_path(format: :json)
      end
      # rubocop:enable RSpec/AnyInstance

      let(:payload) { { test: 'test' } }

      specify { expect(response.content_type).to eq('application/json; charset=utf-8') }
      specify { expect(response.body).to eql(payload.to_json) }

      it_behaves_like 'a disabler of view only actions'
    end
  end
end
