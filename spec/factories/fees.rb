# == Schema Information
#
# Table name: fees
#
#  id                    :integer          not null, primary key
#  claim_id              :integer
#  fee_type_id           :integer
#  quantity              :decimal(, )
#  amount                :decimal(, )
#  created_at            :datetime
#  updated_at            :datetime
#  uuid                  :uuid
#  rate                  :decimal(, )
#  type                  :string
#  warrant_issued_date   :date
#  warrant_executed_date :date
#  sub_type_id           :integer
#  case_numbers          :string
#  date                  :date
#

FactoryBot.define do

  factory :fixed_fee, class: Fee::FixedFee do
    claim
    fee_type { build :fixed_fee_type }
    quantity 1
    rate 25

    trait :lgfs do
      fee_type { build :fixed_fee_type, :lgfs }
      quantity 0
      rate 0
      amount 25
      date 3.days.ago
    end

    trait :noc_fee do
      fee_type { build :fixed_fee_type, description: 'Number of cases uplift', code: 'NOC', unique_code: 'FXNOC', calculated: true }
    end

    trait :fxcbr_fee do
      fee_type { build :fixed_fee_type, :fxcbr }
    end

    trait :fxcbu_fee do
      fee_type { build :fixed_fee_type, :fxcbu }
    end
  end

  factory :misc_fee, class: Fee::MiscFee do
    claim
    fee_type { build :misc_fee_type }
    quantity 1
    rate 25

    trait :lgfs do
      fee_type { build :misc_fee_type, :lgfs }
      quantity 0
      rate 0
      amount 25
    end

    trait :spf_fee do
      fee_type { build :misc_fee_type, :spf }
    end

    trait :mispf_fee do
      fee_type { build :misc_fee_type, :mispf }
    end
  end

  factory :warrant_fee, class: Fee::WarrantFee do
    claim
    fee_type { build :warrant_fee_type }
    warrant_issued_date Fee::WarrantFeeValidator::MINIMUM_PERIOD_SINCE_ISSUED.ago
    amount 25.01

    trait :warrant_executed do
      warrant_exectuted_date { warrant_issued_date + 5.days }
    end

    after(:build) do |fee|
      fee.fee_type = Fee::WarrantFeeType.instance || build(:warrant_fee_type)
    end
  end

  factory :interim_fee, class: Fee::InterimFee do
    claim { build :interim_claim }
    fee_type { build :interim_fee_type }
    quantity 2
    amount 245.56
    uuid SecureRandom.uuid
    rate nil

    trait :disbursement do
      claim { build :interim_claim, disbursements: build_list(:disbursement, 1) }
      fee_type { build :interim_fee_type, :disbursement_only }
      amount nil
      quantity nil
    end

    trait :warrant do
      fee_type { build :interim_fee_type, :warrant }
      quantity nil
      amount 25.02
      warrant_issued_date 5.days.ago
    end

    trait :effective_pcmh do
      fee_type { build :interim_fee_type, :effective_pcmh }
      quantity nil
    end

    trait :trial_start do
      fee_type { build :interim_fee_type, :trial_start }
      quantity 1
    end

    trait :retrial_start do
      fee_type { build :interim_fee_type, :retrial_start }
      quantity 1
    end

    trait :retrial_new_solicitor do
      fee_type { build :interim_fee_type, :retrial_new_solicitor }
      quantity nil
    end
  end

  factory :basic_fee, class: Fee::BasicFee do
    claim
    fee_type { build :basic_fee_type }
    quantity 1
    rate 25

    trait :baf_fee do
      fee_type { build :basic_fee_type, description: 'Basic Fee', code: 'BAF', unique_code: 'BABAF' }
    end

    trait :daf_fee do
      fee_type {build  :basic_fee_type, description: 'Daily Attendance Fee (3 to 40)', code: 'DAF', unique_code: 'BADAF' }
    end

    trait :dah_fee do
      fee_type { build :basic_fee_type, description: 'Daily Attendance Fee (41 to 50)', code: 'DAH', unique_code: 'BADAH' }
    end

    trait :daj_fee do
      fee_type { build :basic_fee_type, description: 'Daily Attendance Fee (50+)', code: 'DAJ', unique_code: 'BADAJ' }
    end

    trait :pcm_fee do
      fee_type { build :basic_fee_type, description: 'Plea and Case Management Hearing', code: 'PCM' }
    end

    trait :ppe_fee do
      rate 0
      amount 25
      fee_type { build :basic_fee_type, description: 'Pages of prosecution evidence', code: 'PPE', unique_code: 'BAPPE', calculated: false }
    end

    trait :ndr_fee do
      fee_type { build :basic_fee_type, description: 'Number of defendants uplift', code: 'NDR', unique_code: 'BANDR', calculated: true }
    end

    trait :noc_fee do
      fee_type { build :basic_fee_type, description: 'Number of cases uplift', code: 'NOC', unique_code: 'BANOC', calculated: true }
    end

    trait :npw_fee do
      rate 0
      amount 25
      fee_type { build :basic_fee_type, description: 'Number of prosecution witnesses', code: 'NPW', unique_code: 'BANPW', calculated: false }
    end

    trait :saf_fee do
      fee_type { build :basic_fee_type, description: 'Standard appearance fee', code: 'SAF', unique_code: 'BASAF' }
    end
  end

  factory :transfer_fee, class: Fee::TransferFee do
    claim { build :transfer_claim }
    fee_type { build :transfer_fee_type }
    quantity 0
    rate 0
    amount 25
  end

  factory :graduated_fee, class: Fee::GraduatedFee do
    claim
    fee_type { build :graduated_fee_type }
    quantity 1
    amount 25
    rate 0
    date 3.days.ago

    trait :guilty_plea_fee do
      fee_type { build(:graduated_fee_type, description: 'Guilty plea', code: 'GGLTY') }
    end

    trait :trial_fee do
      fee_type { build(:graduated_fee_type, :grtrl) }
    end
  end

  trait :with_date_attended do
    after(:build) do |fee|
      fee.dates_attended << build(:date_attended, attended_item: fee)
    end
  end

  trait :random_values do
    quantity { rand(1..15) }
    rate { rand(50..80) }
    amount   { rand(100..999).round(0) }
  end

  trait :all_zero do
    quantity 0
    rate 0
  end

  trait :from_api do
    claim         { FactoryBot.create :claim, source: 'api' }
  end
end
