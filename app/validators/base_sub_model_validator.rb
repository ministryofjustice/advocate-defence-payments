class BaseSubModelValidator < BaseValidator
  # Override this method in the derived class
  def has_many_association_names
    []
  end

  # Override this method in the derived class
  def has_one_association_names
    []
  end

  def validate(record)
    @result = true
    super
    validate_has_many_associations(record)
    validate_has_one_associations(record)
    remove_unnumbered_submodel_errors_from_base_record(record)
    record.errors.empty? && @result
  end

  private

  def validate_has_many_associations(record)
    has_many_association_names.each do |association_name|
      validate_collection_for(record, association_name)
    end
  end

  def validate_has_one_associations(record)
    has_one_association_names.each do |association_name|
      validate_association_for(record, association_name)
    end
  end

  def validate_collection_for(record, association_name)
    collection = record.__send__(association_name)
    order_column = collection.detect { |item| item.respond_to?(:validation_order) }&.validation_order
    collection = collection.sort_by(&:"#{order_column}") if order_column
    collection.each_with_index do |associated_record, i|
      next if associated_record.marked_for_destruction? || associated_record.valid?
      @result = false
      copy_errors_to_base_record(record, association_name, associated_record, i)
    end
  end

  def validate_association_for(record, association_name)
    associated_record = record.__send__(association_name)
    return if associated_record.nil? || associated_record.destroyed?
    @result = false unless associated_record.valid?
  end

  def copy_errors_to_base_record(base_record, association_name, associated_record, record_num)
    error_prefix = "#{association_name}_attributes_#{record_num}"
    associated_record.errors.each do |error|
      error_suffix = suffix_error_fields? ? "_#{error.attribute}" : ''
      base_record_error_key = [error_prefix, error_suffix].join.to_sym
      base_record.errors.add(base_record_error_key, error.message)
    end
  end

  def remove_unnumbered_submodel_errors_from_base_record(record)
    # DO NOT loop over `errors` because you modify the loop your are iterating over.
    record.errors.attribute_names.each do |attribute|
      record.errors.delete(attribute) if attribute.to_s.include?('.')
    end
  end

  def has_many_association_names_for_errors
    has_many_association_names
  end

  # Override this method in subclasses for associations that should not generate errors in the format:
  #   supplier_number_3_field
  # and instead should remove the field having errors:
  #   supplier_number_3
  #
  def suffix_error_fields?
    true
  end
end
