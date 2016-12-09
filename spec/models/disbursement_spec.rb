# == Schema Information
#
# Table name: disbursements
#
#  id                   :integer          not null, primary key
#  disbursement_type_id :integer
#  claim_id             :integer
#  net_amount           :decimal(, )
#  vat_amount           :decimal(, )
#  created_at           :datetime
#  updated_at           :datetime
#  total                :decimal(, )      default(0.0)
#  uuid                 :uuid
#

require 'rails_helper'

RSpec.describe Disbursement, type: :model do

  it { should belong_to(:disbursement_type) }
  it { should belong_to(:claim) }

  it { should validate_presence_of(:claim).with_message('blank') }

  describe 'comma formatted inputs' do
    [:net_amount, :vat_amount].each do |attribute|
      it "converts input for #{attribute} by stripping commas out" do
        disbursement = build(:disbursement)
        disbursement.send("#{attribute}=", '1,321.55')
        expect(disbursement.send(attribute)).to eq(1321.55)
      end
    end
  end

  describe 'update claim totals' do
    before :all do
      @claim = create(:litigator_claim, :without_fees, apply_vat: true)
      [[5.0, 1.5], [3.0, 1.0]].each do |net, vat|
        create(:disbursement, claim: @claim, net_amount: net, vat_amount: vat)
      end
    end

    after :all do
      clean_database
    end

    it 'calculates the disbursements total amount' do
      expect(@claim.disbursements_total).to eq(8.0)
    end

    it 'calculates the disbursement vat amount' do
      expect(@claim.disbursements_vat).to eq 2.5
    end

    it 'calculates the claim total amount' do
      expect(@claim.total).to eq(8.0)
    end

    it 'calculates the claim vat amount' do
      ap @claim
      ap @claim.expenses
      ap @claim.disbursements
      ap @claim.fees
      expect(@claim.vat_amount).to eq 2.5
    end
  end
end
