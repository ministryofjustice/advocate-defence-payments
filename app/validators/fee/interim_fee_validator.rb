class Fee::InterimFeeValidator < Fee::BaseFeeValidator
  def self.fields
    %i[
      quantity
      rate
      disbursements
    ] + super
  end

  def validate_quantity
    if @record.is_disbursement? || @record.is_interim_warrant?
      validate_absence_or_zero(:quantity, 'present')
    else
      validate_numericality(:quantity, 'numericality', 0, 99_999)
    end
  end

  def validate_amount
    if @record.is_disbursement?
      validate_absence_or_zero(:amount, 'present')
    else
      validate_presence_and_numericality(:amount, minimum: 0.1)
    end
  end

  def validate_rate
    validate_absence_or_zero(:rate, 'present')
  end

  def validate_disbursements
    if @record.is_disbursement?
      add_error(:disbursements, 'blank') if @record.claim.disbursements.empty?
    elsif @record.is_interim_warrant? && @record.claim.disbursements.any?
      add_error(:disbursements, 'present')
    end
  end

  def validate_warrant_issued_date
    return unless @record.is_interim_warrant?
    validate_presence(:warrant_issued_date, 'blank')
    validate_on_or_after(Settings.earliest_permitted_date, :warrant_issued_date, 'check_not_too_far_in_past')
    validate_on_or_before(Date.today, :warrant_issued_date, 'check_not_in_future')
  end

  def validate_warrant_executed_date
    return unless @record.is_interim_warrant?
    validate_on_or_after(@record.warrant_issued_date, :warrant_executed_date, 'warrant_executed_before_issued')
    validate_on_or_before(Date.today, :warrant_executed_date, 'check_not_in_future')
  end
end
