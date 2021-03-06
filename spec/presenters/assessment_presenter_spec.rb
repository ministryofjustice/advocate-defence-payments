require 'rails_helper'

RSpec.describe AssessmentPresenter do
  let(:claim) { create(:claim, apply_vat: true) }
  let(:presenter) { described_class.new(claim.assessment, view) }

  context 'currency fields' do
    let(:currency_pattern) { /£\d,\d{3}\.\d{2}/ }

    before { claim.assessment.update!(fees: 1452.33, expenses: 2455.77, disbursements: 1505.24) }

    it 'totals formatted as currency' do
      expect(presenter.fees_total).to match currency_pattern
      expect(presenter.expenses_total).to match currency_pattern
      expect(presenter.disbursements_total).to match currency_pattern
      expect(presenter.total).to match currency_pattern
      expect(presenter.vat_amount).to match currency_pattern
      expect(presenter.total_inc_vat).to match currency_pattern
    end
  end
end
