require 'ostruct'

# Service to calculate the total "price/bill" for a given fee.
# Note that this price will require input from different attributes
# on the claim and may require input from different CCCD fees
# to be consolidated/munged.
#
module Claims
  module FeeCalculator
    Response = Struct.new(:success?, :data, :errors, :message, keyword_init: true)
    Data = Struct.new(:amount, keyword_init: true)

    class Calculate
      delegate  :earliest_representation_order_date,
                :agfs?,
                :case_type,
                :offence,
                to: :claim

      # TODO: check if these can all be made private
      attr_reader :claim, :options, :fee_type, :advocate_category, :quantity, :current_page_fees

      def initialize(claim, options)
        @claim = claim
        @options = options
      end

      def call
        setup(options)
        response(true, amount)
      rescue StandardError => err
        Rails.logger.error("error: #{err.message}")
        response(false, err, 'Price unavailable')
      end

      private

      def setup(options)
        @fee_type = Fee::BaseFeeType.find(options[:fee_type_id])
        @advocate_category = options[:advocate_category] || claim.advocate_category
        @quantity = options[:quantity] || 1
        @current_page_fees = options[:fees].values
      end

      def amount
        fee_scheme.calculate do |options|
          options[:scenario] = scenario.id
          options[:offence_class] = offence_class
          options[:advocate_type] = advocate_type
          options[:fee_type_code] = fee_type_code_for(fee_type)

          # units
          # TODO: which unit to use and their values need to be dynamically determined.
          # Current code only works assuming there is only one unit type and the quantity of
          # the fee is for that unit type.
          units = fee_scheme.units(options).map { |u| u.id.downcase }
          units.each do |unit|
            options[unit.to_sym] = quantity.to_f
          end

          # TODO: aberrations
          # - elected case not proceeded is a scenario type with ccr fee type code of AGFS_FEE
          # - cracked case discontinued - not sure we should even have this fixed fee in CCCD after speaking to BA??

          # modifiers
          # TODO: modifier needs to be dynamically determined and could be more than one
          # TODO: modifier values should be based on "munging" uplifts and "number of.." fee types
          # rather than actual number of defendants/cases (based on only paying what they ask for logic)
          # options[:number_of_defendants] = 1
          # options[:number_of_cases] = 1
        end
      end

      def scheme_type
        agfs? ? 'AGFS' : 'LGFS'
      end

      def fee_scheme
        @fee_scheme ||= client.fee_schemes(type: scheme_type, case_date: earliest_representation_order_date.to_s(:db))
      end

      # TODO: consider creating a mapping to fee calculator id's
      # (less "safe" but faster/negates the need to query the API)??
      #
      def scenario
        # TODO: create select/find_by calls to list endpoints in client gem
        fee_scheme.scenarios.select do |s|
          s.code.eql?(CCR::CaseTypeAdapter::BILL_SCENARIOS[case_type.fee_type_code.to_sym])
        end&.first
      end

      def offence_class
        # some/all fixed fees do not require offences and they have no bearing on calculated fee amount
        # TODO: make conditional on fee scheme version
        offence&.offence_class&.class_letter || offence&.offence_band&.description
      end

      def advocate_type
        CCR::AdvocateCategoryAdapter.code_for(advocate_category)
      end

      def fee_type_mappings
        [
          # CCR::Fee::BasicFeeAdapter::BASIC_FEE_BILL_MAPPINGS, # TODO: all are AGFS_FEE
          CCR::Fee::FixedFeeAdapter::FIXED_FEE_BILL_MAPPINGS,
          CCR::Fee::MiscFeeAdapter::MISC_FEE_BILL_MAPPINGS
        ].inject(&:merge)
      end

      def fee_type_code_for(fee_type)
        fee_type = case_uplift_parent if fee_type.case_uplift?
        fee_type = defendant_uplift_parent if fee_type.defendant_uplift?
        fee_type_mappings[fee_type&.unique_code&.to_sym][:bill_subtype]
      end

      # TODO: share/take from adapters
      def orphan_uplift?
        %w[FXNOC FXNDR].include?(fee_type.unique_code)
      end

      def current_fee_types
        return @current_fee_types if @current_fee_types
        ids = current_page_fees.map { |pf| pf[:fee_type_id] }
        @current_fee_types = Fee::BaseFeeType.where(id: ids)
      end

      def primary_fee_type_on_page
        primary_fee_types = current_fee_types.where(unique_code: fee_type_mappings.keys)
        return nil if primary_fee_types.size > 1
        primary_fee_types.first
      end

      def case_uplift_parent
        return primary_fee_type_on_page if orphan_uplift?

        # TODO: hacky but there is no relationship between fixed fee "primary" types
        # and their case uplift equivalent.
        # - could create relationship on models/database
        #
        Fee::BaseFeeType
          .where('description = ?', fee_type.description.gsub(' uplift', ''))
          .where.not('description ILIKE ?', '%uplift%')&.first
      end

      def defendant_uplift_parent
        return primary_fee_type_on_page if orphan_uplift?
      end

      def response(success, data, message = nil)
        return Response.new(success?: true, data: Data.new(amount: data), errors: nil, message: message) if success
        Response.new(success?: false, data: nil, errors: [data], message: message)
      end

      def client
        @client ||= LAA::FeeCalculator.client
      end
    end
  end
end
