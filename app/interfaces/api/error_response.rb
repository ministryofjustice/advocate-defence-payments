# #############################################################
# ErrorResponse Class: Retrieves validation error messages from
# translations file(s) and responds to erroneous API endpoint
# request with those error messages.
#
# error translations are divided into submodels:
# - Claim errors have no submodel.
# - Fee error translations are broken down into
#   the three different types plus a fallback type
#   ,in case the type is unknown.
# - Any other claim submodel should use its model
#   name in snake case.
#
# NOTE: for API we "spoof" the submodel count/number/instance
#       as 1
# #############################################################

module API
  class ErrorResponse
    attr_reader :body
    attr_reader :status

    attr_reader :error_messages

    VALID_MODEL_KLASSES = [
      Fee::GraduatedFee, Fee::InterimFee, Fee::TransferFee, Fee::BasicFee, Fee::MiscFee, Fee::FixedFee,
      Expense, Disbursement, Defendant, DateAttended, RepresentationOrder,
      Claim::AdvocateClaim, Claim::AdvocateInterimClaim, Claim::AdvocateSupplementaryClaim,
      Claim::LitigatorClaim, Claim::InterimClaim, Claim::TransferClaim, Claim::AdvocateHardshipClaim,
      Claim::LitigatorHardshipClaim
    ].freeze

    def initialize(object)
      @error_messages = []
      @translations = translations
      if VALID_MODEL_KLASSES.include? object.class
        @model = object
        build_error_response
      else
        @status = object.try(:message) == 'Unauthorised' ? 401 : 400
        error_msg = object.try(:message).nil? ? "No message provided by object #{object.class.name}" : object.message
        @body = error_messages.push(error: error_msg)
      end
    end

    private

    def translations
      message_file ||= Rails.root.join('config', 'locales', "error_messages.#{I18n.locale}.yml")
      YAML.load_file(message_file)
    end

    def submodel_prefix
      submodel_instance_num = ''
      m = @model

      if m.is_a?(Fee::BaseFee)
        submodel = m.class.name.demodulize.underscore
        submodel_instance_num = "#{submodel}_1_"
      elsif !m.try(:claim).nil?
        submodel_instance_num = "#{m.class.name.underscore}_1_"
      end

      submodel_instance_num
    end

    # format of field name determines lookup in translations
    def format_field_name(field_name)
      (submodel_prefix + field_name.to_s).to_s.to_sym
    end

    def fetch_and_translate_error_messages
      @model.errors.each do |error|
        message = error.message
        field_name = format_field_name(error.attribute)
        emt = ErrorMessageTranslator.new(@translations, field_name, message)
        error_messages.push(error: emt.api_message)
      end
    end

    def build_error_response
      raise 'unable to build error response as no errors were found' if @model.errors.empty?

      fetch_and_translate_error_messages
      @body = error_messages
      @status = 400
    end
  end
end
