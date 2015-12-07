require 'rails_helper'

describe RedeterminationPresenter do
  
  let(:rd)              { FactoryGirl.create :redetermination, fees: 1452.33, expenses: 2455.77 }
  let(:presenter)       { RedeterminationPresenter.new(rd, view) }

  describe '#created_at' do
    it 'should properly format the time' do
      allow(rd).to receive(:created_at).and_return(Time.local(2015, 8, 13, 13, 15, 22))
      expect(presenter.created_at).to eq('13/08/2015 13:15')
    end
  end

  
  context 'currency fields' do
  
    it 'should format currency amount' do
      expect(presenter.fees_total).to eq '£1,452.33'
      expect(presenter.expenses_total).to eq '£2,455.77'
      expect(presenter.total).to eq '£3,908.10'
      expect(presenter.vat_amount).to eq '£683.92'
      expect(presenter.total_inc_vat).to eq '£4,592.02'
    end
  end

end
