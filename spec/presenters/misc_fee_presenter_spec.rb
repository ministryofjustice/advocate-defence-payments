require 'rails_helper'

describe Fee::MiscFeePresenter do
  let(:misc_fee) { instance_double(Fee::MiscFee, claim: double, quantity_is_decimal?: false, errors: { quantity: [] }) }
  let(:presenter) { Fee::MiscFeePresenter.new(misc_fee, view) }

  context '#rate' do
    it 'calls not_applicable_html when belonging to an LGFS claim' do
      allow(presenter).to receive(:agfs?).and_return false
      expect(presenter).to receive(:not_applicable_html)
      presenter.rate
    end

    it 'returns number as currency for calculated fees belonging to an AGFS claim' do
      allow(presenter).to receive(:agfs?).and_return true
      allow(misc_fee).to receive(:calculated?).and_return true
      expect(misc_fee).to receive(:rate).and_return 12.01
      expect(presenter.rate).to eq '£12.01'
    end

    it 'returns not_applicable for uncalculated fees belonging to an AGFS claim' do
      allow(presenter).to receive(:agfs?).and_return true
      allow(misc_fee).to receive(:calculated?).and_return false
      expect(presenter).to receive(:not_applicable)
      presenter.rate
    end
  end

  context '#quantity' do
    it 'returns fee quantity when belonging to an AGFS claim' do
      allow(presenter).to receive(:agfs?).and_return true
      expect(misc_fee).to receive(:quantity)
      presenter.quantity
    end

    it 'returns not_applicable_html when belonging to an LGFS claim' do
      allow(presenter).to receive(:agfs?).and_return false
      expect(presenter).to receive(:not_applicable_html)
      presenter.quantity
    end
  end
end
