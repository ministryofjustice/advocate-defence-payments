# == Schema Information
#
# Table name: fee_types
#
#  id                  :integer          not null, primary key
#  description         :string
#  code                :string
#  created_at          :datetime
#  updated_at          :datetime
#  max_amount          :decimal(, )
#  calculated          :boolean          default(TRUE)
#  type                :string
#  roles               :string
#  parent_id           :integer
#  quantity_is_decimal :boolean          default(FALSE)
#  unique_code         :string
#
require 'rails_helper'
require_relative 'shared_examples_for_defendant_uplifts'

module Fee
  describe MiscFeeType do
    let(:fee_type) { build :misc_fee_type }
    it_behaves_like 'defendant upliftable'

    describe '#fee_category_name' do
      it 'returns the category name' do
          expect(fee_type.fee_category_name).to eq 'Miscellaneous Fees'
      end
    end

    describe 'default scope' do
      before do
        create(:misc_fee_type, description: 'Ppppp')
        create(:misc_fee_type, description: 'Xxxxx')
        create(:misc_fee_type, description: 'Sssss')
      end

      it 'orders by description ascending' do
        expect(Fee::MiscFeeType.all.map(&:description)).to eq ['Ppppp','Sssss','Xxxxx']
      end
    end

    describe '#case_uplift?' do
      subject { fee_type.case_uplift? }

      # No Misc fees are case uplifts
      it 'returns false when fee_type is not Case Uplift' do
        fee_type.code = 'MIUPL'
        is_expected.to be_falsey
      end
    end
  end
end
