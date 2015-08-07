require 'rails_helper'

RSpec.describe FeePresenter do

  let(:claim)         { create(:claim) }
  let(:fee_type)      { create(:fee_type, description: 'Basic fee type C') }
  let(:fee)           { create(:fee, quantity: 4, claim: claim, fee_type: fee_type) }

  it '#dates_attended_delimited_string' do
    create(:date_attended, attended_item: fee, date: Date.parse('21/05/2015'), date_to: Date.parse('23/05/2015'))
    create(:date_attended, attended_item: fee, date: Date.parse('25/05/2015'), date_to: nil)
    claim.fees.each do |fee|
      fee = FeePresenter.new(fee, view)
      expect(fee.dates_attended_delimited_string).to eql('21/05/2015 - 23/05/2015, 25/05/2015')
    end
  end

end
