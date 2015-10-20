require 'rails_helper'

RSpec.describe Claims::FinancialSummary, type: :model do
  # Uses default VAT rate factory (implicitly) with VAT rate of 17.5%

  context 'by advocate' do

    # TODO should not rely on values in factory which may change
    let!(:submitted_claim)  { create(:submitted_claim,) }
    let!(:allocated_claim)  { create(:allocated_claim,) }
    let!(:old_part_authorised_claim) do
      Timecop.freeze(Time.now - 1.week) do
        claim = create(:part_authorised_claim)
        create(:assessment, claim: claim, fees: claim.fees_total/2, expenses: claim.expenses_total)
        claim
      end
    end

    let!(:part_authorised_claim) do
      claim = create(:part_authorised_claim)
      create(:assessment, claim: claim, fees: claim.fees_total/2, expenses: claim.expenses_total)
      claim
    end

    let!(:authorised_claim) do
      claim = create(:authorised_claim)
      create(:assessment, claim: claim, fees: claim.fees_total, expenses: claim.expenses_total)
      claim
    end

    let(:advocate_with_vat)           { create(:advocate, apply_vat: true) }
    let(:advocate_without_vat)        { create(:advocate, apply_vat: false) }
    let(:another_advocate)            { create(:advocate) }
    let(:other_advocate_claim)        { create(:claim) }

    # subject { Claims::FinancialSummary.new(advocate) }

    context 'with VAT applied' do
      before do
        [submitted_claim, allocated_claim, part_authorised_claim, authorised_claim, old_part_authorised_claim].each do |claim|
          claim.advocate = advocate_with_vat
          claim.creator = advocate_with_vat
          claim.save!
        end

        other_advocate_claim.advocate = another_advocate
        other_advocate_claim.creator = another_advocate
      end

      let(:summary)           { Claims::FinancialSummary.new(advocate_with_vat) }

      describe '#total_outstanding_claim_value' do
        it 'calculates the value of outstanding claims' do
          expect(summary.total_outstanding_claim_value).to eq(58.76)
        end
      end

      describe '#total_authorised_claim_value' do
        before do
          part_authorised_claim.advocate = advocate_with_vat
          part_authorised_claim.save!
        end

        it 'calculates the value of authorised claims since the beginning of the week' do
          expect(summary.total_authorised_claim_value).to eq(44.07)
        end
      end
    end


    context 'with no VAT applied' do
      let(:summary)           { Claims::FinancialSummary.new(advocate_without_vat) }
      before do
        [submitted_claim, allocated_claim, part_authorised_claim, authorised_claim, old_part_authorised_claim].each do |claim|
          claim.advocate = advocate_without_vat
          claim.creator = advocate_without_vat
          claim.save!
        end
      end

      describe '#total_outstanding_claim_value' do
        it 'calculates the value of outstanding claims' do
          expect(summary.total_outstanding_claim_value).to eq(50.00)
        end
      end

      describe '#total_authorised_claim_value' do

        it 'calculates the value of authorised claims since the beginning of the week' do
          expect(summary.total_authorised_claim_value).to eq(37.5)
        end
      end
    end
  end

 

  context 'by Chambers' do
    let!(:submitted_claim)  { create(:submitted_claim, total: 103.56) }
    let!(:allocated_claim)  { create(:allocated_claim, total: 56.21) }

    let!(:part_authorised_claim) do
      claim = create(:part_authorised_claim, total: 211)
      create(:assessment, claim: claim, fees: 9.99, expenses: 1.55)
      claim
    end
    let!(:authorised_claim) do
      claim = create(:authorised_claim, total: 89)
      create(:assessment, claim: claim, fees: 40, expenses: 49)
      claim
    end

    let(:chamber)                 { create(:chamber) }
    let(:other_chamber)           { create(:chamber) }
    let(:advocate_admin)          { create(:advocate, role: 'admin', chamber: chamber, apply_vat: true) }
    let(:advocate_with_vat)       { create(:advocate, chamber: chamber, apply_vat: true) }
    let(:advocate_without_vat)    { create(:advocate, chamber: chamber, apply_vat: false) }
    let(:another_advocate_admin)  { create(:advocate, role: 'admin', chamber: other_chamber) }
    let(:other_chamber_claim)     { create(:claim) }


    before do
      other_chamber_claim.advocate = another_advocate_admin
      other_chamber_claim.creator = another_advocate_admin
    end

    context 'with VAT' do
      let(:summary)   { Claims::FinancialSummary.new(advocate_with_vat) }

      before do
        [submitted_claim, allocated_claim, part_authorised_claim, authorised_claim].each do |claim|
          claim.advocate = advocate_with_vat
          claim.creator = advocate_with_vat
          claim.save!
        end
      end

      describe '#total_outstanding_claim_value' do
        it 'calculates the value of outstanding claims' do
          expect(summary.total_outstanding_claim_value).to eq(58.76)
        end
      end

      describe '#total_authorised_claim_value' do
        it 'calculates the value of authorised claims' do
          expect(summary.total_authorised_claim_value).to eq(118.14)
        end
      end
    end

    context 'claim without VAT applied' do
      let(:summary)   { Claims::FinancialSummary.new(advocate_without_vat) }
      before do
        [submitted_claim, allocated_claim, part_authorised_claim, authorised_claim].each do |claim|
          claim.advocate = advocate_without_vat
          claim.creator = advocate_without_vat
          claim.save!
        end
      end

      it 'calculates the value of outstanding claims' do
        expect(summary.total_outstanding_claim_value).to eq(50.0)
      end

      it 'calculates the value of authorised claims' do
        expect(summary.total_authorised_claim_value).to eq(100.54)
      end

      describe '#outstanding_claims' do
        it 'returns outstanding claims only' do
          expect(summary.outstanding_claims).to include(submitted_claim, allocated_claim)
          expect(summary.outstanding_claims).to_not include(authorised_claim, part_authorised_claim, other_chamber_claim)
        end
      end

      describe '#authorised_claims' do
        it 'returns authorised claims only' do
          expect(summary.authorised_claims).to include(authorised_claim, authorised_claim)
          expect(summary.authorised_claims).to_not include(submitted_claim, allocated_claim, other_chamber_claim)
        end
      end
    end
  end
end
