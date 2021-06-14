require 'rails_helper'

RSpec.describe 'Servicedown mode', type: :request do
  before do
    allow(Settings).to receive(:maintenance_mode_enabled?).and_return(true)
    Rails.application.reload_routes!
  end

  after do
    allow(Settings).to receive(:maintenance_mode_enabled?).and_return(false)
    Rails.application.reload_routes!
  end

  shared_examples 'maintenance page' do |options = {}|
    it { expect(response).to have_http_status(options[:status] || 503) }
    it { expect(response.body).to include('planned maintenance') }
  end

  shared_examples 'maintenance json' do
    it { expect(response).to have_http_status :service_unavailable }
    it { expect(response.body).to be_json }
    it { expect(response.body).to include_json({ error: 'Service temporarily unavailable' }.to_json) }
  end

  context '/ping' do
    before { get '/ping' }
    it { expect(response).to be_ok }
    it { expect(response.body).to be_json }
  end

  context '/healthcheck' do
    before do
      allow(Sidekiq::ProcessSet).to receive(:new).and_return(instance_double(Sidekiq::ProcessSet, size: 1))
      allow(Sidekiq::RetrySet).to receive(:new).and_return(instance_double(Sidekiq::RetrySet, size: 0))
      allow(Sidekiq::DeadSet).to receive(:new).and_return(instance_double(Sidekiq::DeadSet, size: 0))
      allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
      connection = double('connection', info: {})
      allow(Sidekiq).to receive(:redis).and_yield(connection)
      get '/healthcheck'
    end

    it { expect(response).to be_ok }
    it { expect(response.body).to be_json }
  end

  context 'kubernetes' do
    before do
      config_options = double(Config::Options, region: 'eu-west-2')
      allow(Settings).to receive(:aws).and_return(config_options)
    end

    context 'web page requests (html)' do
      context 'sign in' do
        before { get '/users/sign_in' }
        it_behaves_like 'maintenance page'
      end
    end

    context 'caseworker' do
      before do
        sign_in(user)
      end

      let(:user) { create(:case_worker).user }
      context '/case_workers/claims' do
        before { get case_workers_home_path }
        it_behaves_like 'maintenance page'
      end
    end

    context 'advocate' do
      before { sign_in user }
      let(:user) { create(:external_user, :advocate).user }

      context '/external_user/claims' do
        before { get external_users_claims_path }
        it_behaves_like 'maintenance page'
      end

      context '/advocates/claims/new' do
        before { get new_advocates_claim_path }
        it_behaves_like 'maintenance page'
      end
    end
  end

  context 'api requests (json)' do
    let(:user) { create(:external_user, :advocate).user }

    context '/api/case_types' do
      before { get '/api/case_types', params: { api_key: user.persona.provider.api_key, format: :json } }
      it_behaves_like 'maintenance json'
    end
  end

  context 'formatted responses' do
    context 'html' do
      before { get '/', params: { format: :html } }
      it_behaves_like 'maintenance page'
    end

    context 'json' do
      before { get '/', params: { format: :json } }
      it_behaves_like 'maintenance json'
    end

    context 'ajax' do
      before { get '/', xhr: true, params: { format: :js } }
      it_behaves_like 'maintenance json'
    end

    context 'all other' do
      before { get '/', params: { format: :axd } }
      it { expect(response).to have_http_status :service_unavailable }
      it { expect(response.body).to include('Service temporarily unavailable') }
    end
  end
end
