require 'rails_helper'
require 'spec_helper'
require 'api_spec_helper'

RSpec::Matchers.define :be_valid_ccr_claim_json do
  match do |response|
    schema_path = ClaimJsonSchemaValidator::CCR_SCHEMA_FILE
    @errors = JSON::Validator.fully_validate(schema_path, response.respond_to?(:body) ? response.body : response)
    @errors.empty?
  end

  description do
    "be valid against the CCR claim JSON schema"
  end

  failure_message do |response|
    spacer = "\s" * 2
    "expected JSON to be valid against CCR formatted claim schema but the following errors were raised:\n" +
    @errors.each_with_index.map { |error, idx| "#{spacer}#{idx+1}. #{error}"}.join("\n")
  end
end

describe API::V2::CCRClaim do
  include Rack::Test::Methods
  include ApiSpecHelper

  def is_valid_ccr_json(response)
    expect(response).to be_valid_ccr_claim_json
  end

  after(:all) { clean_database }

  before(:all) do
    @case_worker = create(:case_worker, :admin)
    @claim = create(:authorised_claim, :without_fees).tap do |claim|
      # NOTE: this will also create the BABAF basic fee TYPE and MISPF misc fee TYPE
      create(:basic_fee, :baf_fee, claim: claim, quantity: 1)
      create(:misc_fee, :mispf_fee, :with_date_attended, claim: claim)
    end
  end

  # mock a Trial case type's fee_type_code as factories
  # do NOT create real/mappable fee type codes
  before do
    allow_any_instance_of(CaseType).to receive(:fee_type_code).and_return 'GRTRL'
  end

  def do_request(claim_uuid: @claim.uuid, api_key: @case_worker.user.api_key)
    get "/api/ccr/claims/#{claim_uuid}", {api_key: api_key}, {format: :json}
  end

  describe 'GET /ccr/claim/:uuid?api_key=:api_key' do
    it 'returns 406, Not Acceptable, if requested API version (via header) is not supported' do
      header 'Accept-Version', 'v1'

      do_request
      expect(last_response.status).to eq 406
      expect(last_response.body).to include('The requested version is not supported.')
    end

    it 'requires an API key' do
      do_request(api_key: nil)
      expect(last_response.status).to eq 401
      expect(last_response.body).to include('Unauthorised')
    end

    context 'claim not found' do
      it 'respond not found when claim is not found' do
        do_request(claim_uuid: '123-456-789')
        expect(last_response.status).to eq 404
        expect(last_response.body).to include('Claim not found')
      end
    end

    context 'JSON response' do
      subject(:response) { do_request }

      it { is_valid_ccr_json(response) }
    end

    context 'defendants' do
      subject(:response) do
        do_request(claim_uuid: @claim.uuid, api_key: @case_worker.user.api_key).body
      end

      before do
        travel_to 2.day.from_now do
          create(:defendant, claim: @claim)
        end
      end

      it 'returns multiple defendants' do
        expect(response).to have_json_size(2).at_path('defendants')
      end

      it 'returns defendants in order created marking earliest created as the "main" defendant' do
        expect(response).to be_json_eql('true').at_path('defendants/0/main_defendant')
      end

      context 'representation orders' do
        it 'returns multiple representation orders' do
          expect(response).to have_json_size(2).at_path('defendants/0/representation_orders')
        end

        # NOTE: use of factory defaults results in two rep orders for the first
        # defendant with dates 400 and 380 days before claim created
        it 'returns earliest rep order first (per defendant)' do
          expect(response).to be_json_eql(@claim.earliest_representation_order_date.to_json).at_path('defendants/0/representation_orders/0/representation_order_date')
        end
      end
    end

    context 'bills' do
      subject(:response) { do_request(claim_uuid: claim.uuid, api_key: @case_worker.user.api_key).body }
      subject(:bills) { JSON.parse(response)['bills'] }

      let(:claim) do
        create(:authorised_claim, :without_fees)
      end

      it 'returns empty array if no bills found' do
        expect(response).to have_json_size(0).at_path("bills")
        expect(bills).to be_an Array
        expect(bills).to be_empty
      end

      context 'advocate fee' do
        it { is_valid_ccr_json(response) }

        it 'not added to bills array when no basic fees are being claimed' do
          allow_any_instance_of(Fee::BasicFee).to receive_messages(rate: 0, quantity: 0, amount: 0)
          expect(response).to have_json_size(0).at_path("bills")
        end

        it 'not added to bills array when only inapplicable basic fees claimed' do
          allow_any_instance_of(Fee::BasicFeeType).to receive(:unique_code).and_return 'BAPCM'
          allow_any_instance_of(Fee::BasicFee).to receive_messages(rate: 1, quantity: 2, amount: 2)
          expect(response).to_not include("\"bill_type\":\"AGFS_FEE\"")
        end

        it 'not added to bills array when case type does not permit advocate fees' do
          allow_any_instance_of(CaseType).to receive(:fee_type_code).and_return 'FXCON' # mock a contempt case type
          expect(response).to have_json_size(0).at_path("bills")
        end

        context 'bill type' do
          before do
            claim.basic_fees.find_by(fee_type_id: Fee::BasicFeeType.find_by(unique_code: 'BABAF')).update(quantity: 1)
          end

          it 'property included' do
            expect(response).to have_json_path("bills/0/bill_type")
          end

          it 'property type valid' do
            expect(response).to have_json_type(String).at_path "bills/0/bill_type"
          end

          it 'valid value included' do
            expect(response).to be_json_eql("AGFS_FEE".to_json).at_path "bills/0/bill_type"
          end
        end

        context 'bill sub type' do
          before do
            claim.basic_fees.find_by(fee_type_id: Fee::BasicFeeType.find_by(unique_code: 'BABAF')).update(quantity: 1)
          end

          it 'property included' do
            expect(response).to have_json_path("bills/0/bill_subtype")
          end

          it 'property type valid' do
            expect(response).to have_json_type(String).at_path "bills/0/bill_subtype"
          end

          it 'valid value included' do
            expect(response).to be_json_eql("AGFS_FEE".to_json).at_path "bills/0/bill_subtype"
          end
        end

        context 'pages of prosecution evidence' do
          subject(:response) do
            do_request(claim_uuid: claim.uuid, api_key: @case_worker.user.api_key).body
          end

          before do
            create(:basic_fee, :ppe_fee, claim: claim, quantity: 1024)
          end

          it 'property included' do
            expect(response).to have_json_path("bills/0/ppe")
          end

          it 'property type valid' do
            expect(response).to have_json_type(String).at_path "bills/0/ppe"
          end

          it 'value taken from the Pages of prosecution evidence Fee quantity' do
            expect(response).to be_json_eql("1024".to_json).at_path "bills/0/ppe"
          end
        end

        context 'number of cases uplifts' do
          subject(:response) do
            do_request(claim_uuid: claim.uuid, api_key: @case_worker.user.api_key).body
          end

          before do
            create(:basic_fee, :noc_fee, claim: claim, quantity: 2, case_numbers: 'T20170001,T20170002')
          end

          it 'property included' do
            expect(response).to have_json_path("bills/0/number_of_cases")
          end

          it 'property type valid' do
            expect(response).to have_json_type(String).at_path "bills/0/number_of_cases"
          end

          it 'calculated from Number of Cases uplift Fee quantity plus 1, for the "main" case' do
            expect(response).to be_json_eql("3".to_json).at_path "bills/0/number_of_cases"
          end
        end

       context 'case numbers' do
          subject(:response) do
            do_request(claim_uuid: claim.uuid, api_key: @case_worker.user.api_key).body
          end

          before do
            create(:basic_fee, :noc_fee, claim: claim, quantity: 2, case_numbers: 'T20172765, T20172766')
          end

          it 'property included' do
            expect(response).to have_json_path("bills/0/case_numbers")
          end

          it 'property type valid' do
            expect(response).to have_json_type(String).at_path "bills/0/case_numbers"
          end

          it 'value taken from the basic fee - number of case uplifts\' case_numbers attribute' do
            expect(response).to be_json_eql("T20172765, T20172766".to_json).at_path "bills/0/case_numbers"
          end
        end

        context 'number_of_defendants' do
          subject(:response) do
            do_request(claim_uuid: claim.uuid, api_key: @case_worker.user.api_key).body
          end

          let(:bandr) { create(:basic_fee_type, :ndr) }

          before do
            claim.basic_fees.find_by(fee_type_id: Fee::BasicFeeType.find_by(unique_code: 'BABAF')).update(quantity: 1)
          end

          it 'property included' do
            expect(response).to have_json_path("bills/0/number_of_defendants")
          end

          it 'property type valid' do
            expect(response).to have_json_type(String).at_path "bills/0/number_of_defendants"
          end

          it 'defaults to 1 if no defendant uplifts claimed' do
            expect(response).to be_json_eql("1".to_json).at_path "bills/0/number_of_defendants"
          end

          it 'calculated from sum of Number of defendant uplift fee quantities plus one for main defendant' do
            create(:basic_fee, fee_type: bandr, claim: claim, quantity: 2)
            expect(response).to be_json_eql("3".to_json).at_path "bills/0/number_of_defendants"
          end
        end

        context 'number of prosecution witnesses' do
          subject(:response) do
            do_request(claim_uuid: claim.uuid, api_key: @case_worker.user.api_key).body
          end

          before do
            create(:basic_fee, :npw_fee, claim: claim, quantity: 3)
          end

          it 'property included' do
            expect(response).to have_json_path("bills/0/number_of_witnesses")
          end

          it 'property type valid' do
            expect(response).to have_json_type(String).at_path "bills/0/number_of_witnesses"
          end

          it 'property value determined from Number of Prosecution Witnesses Fee quantity' do
            expect(response).to be_json_eql("3".to_json).at_path "bills/0/number_of_witnesses"
          end
        end

        context 'daily attendances' do
          subject(:response) do
            do_request(claim_uuid: claim.uuid, api_key: @case_worker.user.api_key).body
          end

          before do
            # NOTE: you must be claiming at least on basic fee for an advocate fee to be submitted
            claim.basic_fees.find_by(fee_type_id: Fee::BasicFeeType.find_by(unique_code: 'BABAF')).update(quantity: 1)
          end

          it 'includes property' do
            expect(response).to have_json_path("bills/0/daily_attendances")
            expect(response).to have_json_type(String).at_path "bills/0/daily_attendances"
          end

          context 'upper bound value' do
            before do
              claim.actual_trial_length = 53
              create(:basic_fee, :daf_fee, claim: claim, quantity: 38, rate: 1.0)
              create(:basic_fee, :dah_fee, claim: claim, quantity: 10, rate: 1.0)
              create(:basic_fee, :daj_fee, claim: claim, quantity: 1, rate: 1.0)
            end

            it 'calculated from Daily Attendanance Fee quantities if they exist' do
              expect(response).to be_json_eql("51".to_json).at_path "bills/0/daily_attendances"
            end
          end

          context 'lower bound value' do
            before do
              claim.update(actual_trial_length: 2)
            end

            it 'calculated from acutal trial length if no daily attendance fees' do
              expect(response).to be_json_eql("2".to_json).at_path "bills/0/daily_attendances"
            end
          end
        end
      end

      context 'fixed fees' do
        subject(:response) do
          do_request(claim_uuid: claim.uuid, api_key: @case_worker.user.api_key).body
        end

        let(:fxcbr) { create(:fixed_fee_type, :fxcbr) }
        let(:fxcbu) { create(:fixed_fee_type, :fxcbu) }
        let(:fxndr) { create(:fixed_fee_type, :fxndr) }
        let(:fxacv) { create(:fixed_fee_type, :fxacv) }

        before do
          allow_any_instance_of(CaseType).to receive(:fee_type_code).and_return 'FXCBR'
        end

        context 'when applicable fixed fee claimed' do
          before do
            create(:fixed_fee, fee_type: fxcbr, claim: claim)
          end

          it { is_valid_ccr_json(response) }

          it 'added to bills' do
            expect(response).to have_json_size(1).at_path("bills")
          end
        end

        context 'when no applicable fixed fee claimed' do
          before do
            create(:fixed_fee, fee_type: fxacv, claim: claim, quantity: 13)
          end

          it 'fee does not impact the bill' do
            expect(response).to have_json_size(1).at_path("bills")
            expect(response).to_not be_json_eql("13".to_json).at_path "bills/0/daily_attendances"
          end
        end

        context 'when no fixed fee exists' do
          it 'fixed fee matching the case type, with defaults, is added to bills' do
            expect(response).to have_json_size(1).at_path("bills")
            expect(response).to be_json_eql("AGFS_ORDER_BRCH".to_json).at_path "bills/0/bill_subtype"
            expect(response).to be_json_eql("1".to_json).at_path "bills/0/daily_attendances"
            expect(response).to be_json_eql("1".to_json).at_path "bills/0/number_of_cases"
            expect(response).to be_json_eql("1".to_json).at_path "bills/0/number_of_defendants"
          end
        end

        context 'daily attendances' do
          before do
            create(:fixed_fee, fee_type: fxcbr, claim: claim, quantity: 3)
            create(:fixed_fee, fee_type: fxcbr, claim: claim, quantity: 2)
          end

          it 'includes property' do
            expect(response).to have_json_path("bills/0/daily_attendances")
            expect(response).to have_json_type(String).at_path "bills/0/daily_attendances"
          end

          it 'calculated from sum of all applicable fixed fee quantities' do
            expect(response).to be_json_eql("5".to_json).at_path "bills/0/daily_attendances"
          end
        end

        context 'case uplift details' do
          before do
            create(:fixed_fee, fee_type: fxcbr, claim: claim, quantity: 1)
            create(:fixed_fee, fee_type: fxcbu, claim: claim, quantity: 2, case_numbers: ' S20170001 , S20170002 ')
            create(:fixed_fee, fee_type: fxcbu, claim: claim, quantity: 2, case_numbers: ' S20170003 , S20170001 ')
          end

          context 'number_of_cases' do
            it 'includes property' do
              expect(response).to have_json_path("bills/0/number_of_cases")
              expect(response).to have_json_type(String).at_path "bills/0/number_of_cases"
            end

            it 'calculated from the count of UNIQUE additional case numbers for all uplift fees of the applicable variety' do
              expect(response).to be_json_eql("4".to_json).at_path "bills/0/number_of_cases"
            end
          end

          context 'case_numbers' do
            it 'includes property' do
              expect(response).to have_json_path("bills/0/case_numbers")
              expect(response).to have_json_type(String).at_path "bills/0/case_numbers"
            end

            it 'consolidated list of UNIQUE additional case numbers for all uplift fees of the applicable variety' do
              %w{S20170001 S20170002 S20170003}.each do |case_number|
                expect(response).to include_json("#{case_number}".to_json).at_path "bills/0/case_numbers"
              end
            end
          end
        end

        context 'number_of_defendants' do
          before do |example|
            create(:fixed_fee, fee_type: fxcbr, claim: claim, quantity: 1)
            create(:fixed_fee, fee_type: fxndr, claim: claim, quantity: 1) unless example.metadata[:skip_uplifts]
          end

          it 'includes property', :skip_uplifts do
            expect(response).to have_json_path("bills/0/number_of_defendants")
            expect(response).to have_json_type(String).at_path "bills/0/number_of_defendants"
          end

          it 'calculated from sum of "number of defendants uplift" fee quanitities on claim plus one' do
            expect(response).to be_json_eql("2".to_json).at_path "bills/0/number_of_defendants"
          end
        end
      end

      context 'miscellaneous fees' do
        subject(:response) do
          do_request(claim_uuid: claim.uuid, api_key: @case_worker.user.api_key).body
        end

        before do
          create(:misc_fee, claim: claim)
          allow_any_instance_of(Fee::MiscFeeType).to receive(:unique_code).and_return 'MIAPH'
        end

        context 'when relevant CCCD fees exist' do
          it { is_valid_ccr_json(response) }

          it 'added to bills' do
            expect(response).to have_json_size(1).at_path("bills")
          end
        end

        context 'when no relevant cccd fee exists' do
          before do
            claim.misc_fees.delete_all
          end

          it 'not added to bills if it is not a miscellaneous fee' do
            expect(response).to have_json_size(0).at_path("bills")
          end
        end

        context 'when CCCD fee maps to a CCR misc fee' do
          before do
            claim.misc_fees.delete_all
            allow_any_instance_of(Fee::BasicFeeType).to receive(:unique_code).and_return 'BAPCM'
          end

          it 'added to bills if it has a value' do
            allow_any_instance_of(Fee::BasicFee).to receive_messages(rate: 1, quantity: 2)
            expect(response).to have_json_size(1).at_path("bills")
            expect(response).to be_json_eql("AGFS_MISC_FEES".to_json).at_path "bills/0/bill_type"
          end

          it 'not added to bills if it has no value' do
            expect(response).to have_json_size(0).at_path("bills")
          end
        end

        context 'bill type' do
          it 'property included' do
            expect(response).to have_json_path("bills/0/bill_type")
          end

          it 'property type valid' do
            expect(response).to have_json_type(String).at_path "bills/0/bill_type"
          end

          it 'property value valid' do
            expect(response).to be_json_eql("AGFS_MISC_FEES".to_json).at_path "bills/0/bill_type"
          end
        end

        context 'bill sub type' do
          it 'property included' do
            expect(response).to have_json_path("bills/0/bill_subtype")
            expect(response).to have_json_type(String).at_path "bills/0/bill_subtype"
          end

          it 'valid value included' do
            expect(response).to be_json_eql("AGFS_ABS_PRC_HF".to_json).at_path "bills/0/bill_subtype"
          end
        end
      end

      context 'expenses' do
        subject(:response) do
          do_request(claim_uuid: claim.uuid, api_key: @case_worker.user.api_key).body
        end

        context 'when an expense is claimed' do
          before { create(:expense, :car_travel, claim: claim) }

          it { is_valid_ccr_json(response) }

          it 'added to bills' do
            expect(response).to have_json_size(1).at_path('bills')
          end
        end
      end
    end
  end
end
