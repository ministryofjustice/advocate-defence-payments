class RedeterminationPresenter < BasePresenter

  presents :redetermination

  def fees_total
    h.number_to_currency(redetermination.fees)
  end

  def expenses_total
    h.number_to_currency(redetermination.expenses)
  end

  def vat_amount
    h.number_to_currency(assessment.vat_amount)
  end

  def total
    h.number_to_currency(assessment.total)
  end

  def total_inc_vat
    h.number_to_currency(assessment.total + assessment.vat_amount)
  end

end
