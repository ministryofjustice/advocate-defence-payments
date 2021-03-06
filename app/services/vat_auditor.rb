class VatAuditor
  def initialize(claim, verbose: false)
    puts ">>>>>>>>>>>> starting audit of claim #{claim.id}"
    @claim = claim
    @result_string = ''
    @result = true
    @verbose = verbose
  end

  def run
    print_claim_totals
    if @claim.agfs?
      @claim.vat_registered? ? audit_agfs_vat_registered : audit_agfs_vat_free
    else
      @claim.vat_registered? ? audit_lgfs_vat_registered : audit_lgfs_vat_fee
    end
    puts @result_string if @verbose
    @result
  end

  private

  def delayed_puts(string)
    @result_string += string + "\n"
  end

  def audit_agfs_vat_registered
    audit_totals
  end

  def audit_agfs_vat_free
    audit_totals
    audit_no_vat_on_fees
  end

  def audit_lgfs_vat_registered
    audit_totals
  end

  def audit_lgfs_vat_fee
    audit_totals
    audit_no_vat_on_fees
  end

  def audit_no_vat_on_fees
    return unless @claim.fees_vat != 0.0
    delayed_puts '    ERROR: VAT on fees for non-VAT registered claim'
    @result = false
  end

  def print_claim_totals
    delayed_puts "#{@claim.class}   #{@claim.id}  vat_registered: #{@claim.vat_registered?}  state: #{@claim.state}"
    delayed_puts format('  total:         %9.2f   VAT: %9.2f', @claim.total, @claim.vat_amount)
    delayed_puts format('  fees:          %9.2f   VAT: %9.2f', @claim.fees_total, @claim.fees_vat)
    delayed_puts format('  expenses:      %9.2f   VAT: %9.2f', @claim.expenses_total, @claim.expenses_vat)
    delayed_puts format('  disbursements: %9.2f   VAT: %9.2f', @claim.disbursements_total, @claim.disbursements_vat)
  end

  def audit_totals
    audit_association(:fees, :fees_total, :amount)
    audit_association(:expenses, :expenses_total, :amount)
    audit_association(:expenses, :expenses_vat, :vat_amount)
    audit_association(:disbursements, :disbursements_total, :net_amount)
    audit_association(:disbursements, :disbursements_vat, :vat_amount)
  end

  def audit_association(assoc_name, claim_total_attr, assoc_attr)
    @result_string += "    #{assoc_name}  #{claim_total_attr}   #{assoc_attr} ..... "
    claim_total =  @claim.__send__(claim_total_attr)
    assoc_totals = @claim.__send__(assoc_name).map(&assoc_attr)
    if claim_total != assoc_totals.sum
      delayed_puts 'ERROR'
      association = "#{assoc_attr} on #{assoc_name}"
      totals = assoc_totals.map(&:to_s).inspect
      delayed_puts "  MISMATCH #{claim_total_attr} of #{claim_total} does not match sum of #{association}: #{totals}"
      @result = false
    else
      delayed_puts 'OK'
    end
  end
end
