class ClaimTextfieldValidator < BaseClaimValidator

  @@fields = [
    :case_type,
    :court,
    :case_number,
    :advocate_category,
    :offence,
    :estimated_trial_length,
    :actual_trial_length
  ]

  @@mandatory_fields = [
    :advocate,
    :creator,
    :amount_assessed,
    :evidence_checklist_ids
  ]

  def self.fields
    @@fields
  end

  def self.mandatory_fields
    @@mandatory_fields
  end

  private

  # ALWAYS required/mandatory
  def validate_advocate
    validate_presence(:advocate, "Advocate cannot be blank, you must provide an advocate")
  end

  # ALWAYS required/mandatory
  def validate_creator
    validate_presence(:creator, "Creator cannot be blank, you must provide an creator")
  end

  # required/mandatory
  def validate_case_type
    validate_presence(:case_type, "Case type cannot be blank, you must select a case type")
  end

  # required/mandatory
  def validate_court
    validate_presence(:court, "Court cannot be blank, you must select a court")
  end

  # required/mandatory
  # format must a letter followed by 8 digits
  def validate_case_number
    validate_presence(:case_number, "Case number cannot be blank, you must enter a case number")
    validate_pattern(:case_number, /^[A-Z]{1}\d{8}$/, "Case number must be in format A12345678 (i.e. 1 capital Letter followed by exactly 8 digits)") unless @record.case_number.blank?
  end

# required/mandatory
# must be one of values in list
def validate_advocate_category
  validate_presence(:advocate_category, "Advocate category cannot be blank, you must select an appropriate advocate category")
  validate_inclusion(:advocate_category, Settings.advocate_categories, "Advocate category must be one of those in the provided list") unless @record.advocate_category.blank?
end

# required/mandatory unless case type is breach of crown court order
def validate_offence
  validate_presence(:offence, "Offence Category cannot be blank, you must select an offence category") unless case_type_in("Breach of Crown Court order")
end

# required/mandatory
# must be greater than or eqaul zero
def validate_estimated_trial_length
  validate_presence(:estimated_trial_length, "Estimated trial length cannot be blank, you must enter an estimated trial length") if trial_dates_required?
  validate_numericality(:estimated_trial_length, 0, nil, "Estimated trial length must be a whole number (0 or above)") unless @record.estimated_trial_length.nil?
end

# required/mandatory
# must be greater than or equal to zero
def validate_actual_trial_length
  validate_presence(:actual_trial_length, "Actual trial length cannot be blank, you must enter an actual trial length") if trial_dates_required?
  validate_numericality(:actual_trial_length, 0, nil, "Actual trial length must be a whole number (0 or above)") unless @record.actual_trial_length.nil?
end

def validate_amount_assessed
  case @record.state
    when 'paid', 'part_paid'
      add_error(:amount_assessed, "Amount assessed cannot be zero for claims in state #{@record.state}") if @record.assessment.blank?
    when 'awaiting_info_from_court', 'draft', 'refused', 'rejected', 'submitted'
      add_error(:amount_assessed, "Amount assessed must be zero for claims in state #{@record.state}") if @record.assessment.present?
  end
end

def validate_evidence_checklist_ids
  raise ActiveRecord::SerializationTypeMismatch.new("Attribute was supposed to be a Array, but was a #{@record.evidence_checklist_ids.class}.") unless @record.evidence_checklist_ids.is_a?(Array)

  # prevent non-numeric array elements
  # NOTE: non-numeric strings/chars will yield a value of 0 and this is checked for to add an error
  @record.evidence_checklist_ids = @record.evidence_checklist_ids.select(&:present?).map(&:to_i)
  if @record.evidence_checklist_ids.include?(0)
    add_error(:evidence_checklist_ids, "Evidence checklist ids are of an invalid type or zero, please use valid Evidence checklist ids")
    return
  end

  # prevent array elements that do no represent a doctype
  valid_doctype_ids = DocType.all.map(&:id)
  @record.evidence_checklist_ids.each do |id|
    unless valid_doctype_ids.include?(id)
      add_error(:evidence_checklist_ids, "Evidence checklist id #{id} is invalid, please use valid evidence checklist ids")
    end
  end

end


# local helpers
# ---------------------------
def trial_dates_required?
  @record.case_type.requires_trial_dates rescue false
end

end