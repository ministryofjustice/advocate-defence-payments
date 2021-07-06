class ErrorPresenter
  SUBMODEL_REGEX = /^(\S+?)(_(\d+)_)(\S+)$/.freeze

  attr_reader :error_details

  def initialize(claim, message_file = nil)
    @claim = claim
    @errors = claim.errors
    message_file ||= "#{Rails.root}/config/locales/error_messages.#{I18n.locale}.yml"
    @translations = YAML.load_file(message_file)
    @error_details = ErrorDetailCollection.new
    generate_messages
  end

  delegate :errors_for?, :header_errors, :size, :short_messages_for, to: :error_details
  alias key? errors_for?
  alias field_level_error_for short_messages_for

  private

  def generate_messages
    @errors.each do |error|
      attribute = error.attribute
      messages = ErrorMessageTranslator.new(@translations, error.attribute, error.message)
      next if @error_details[attribute] && @error_details[attribute][0].long_message.eql?(messages.long_message)
      @error_details[attribute] = ErrorDetail.new(
        attribute,
        messages.long_message,
        messages.short_message,
        messages.api_message,
        generate_sequence(attribute)
      )
    end
  end

  def last_parent_attribute(_translations, key)
    attribute = ErrorMessageTranslator.association_key(key)
    while attribute =~ SUBMODEL_REGEX
      parent_model = Regexp.last_match(1)
      attribute = Regexp.last_match(4)
    end
    [parent_model, attribute]
  end

  def is_submodel_key?(key)
    key =~ SUBMODEL_REGEX
  end

  def translations_sub_set_and_parent_sequence(key)
    key = key.to_s
    parent_sequence = 0
    if is_submodel_key?(key)
      parent_model, attribute = last_parent_attribute(@translations, key)
      parent_sequence = @translations.dig(parent_model, '_seq') || 0
      translations_subset = @translations.dig(parent_model, attribute)
    else
      translations_subset = @translations[key]
    end

    [translations_subset, parent_sequence]
  end

  # NOTE:
  # sequence = (attribute's _seq value + parent's _seq value) or parents _seq or 99999
  #
  def generate_sequence(key)
    translations_subset, parent_sequence = translations_sub_set_and_parent_sequence(key)
    begin
      translations_subset['_seq'].present? ? translations_subset['_seq'] + parent_sequence : parent_sequence || 99_999
    rescue StandardError
      99_999
    end
  end
end
