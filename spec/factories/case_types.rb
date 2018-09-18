# == Schema Information
#
# Table name: case_types
#
#  id                      :integer          not null, primary key
#  name                    :string
#  is_fixed_fee            :boolean
#  created_at              :datetime
#  updated_at              :datetime
#  requires_cracked_dates  :boolean
#  requires_trial_dates    :boolean
#  allow_pcmh_fee_type     :boolean          default(FALSE)
#  requires_maat_reference :boolean          default(FALSE)
#  requires_retrial_dates  :boolean          default(FALSE)
#  roles                   :string
#  fee_type_code           :string
#  uuid                    :uuid
#

FactoryBot.define do
  factory :case_type do
    sequence(:name)             { |n| "Case Type #{n}" }
    is_fixed_fee                false
    requires_cracked_dates      false
    requires_trial_dates        false
    requires_maat_reference     true
    roles                       %w{ agfs lgfs }
    uuid SecureRandom.uuid

    trait :fixed_fee do
      name 'Fixed fee'
      is_fixed_fee true
    end

    trait :graduated_fee do
      name 'Graduated fee'
      is_fixed_fee false
      fee_type_code { build(:graduated_fee_type).code }
    end

    trait :requires_cracked_dates do
      requires_cracked_dates true
    end

    trait :requires_trial_dates do
      requires_trial_dates true
    end

    trait :requires_retrial_dates do
      requires_retrial_dates true
    end

    trait :elected_cases_not_proceeded do
      name 'Elected cases not proceeded'
      is_fixed_fee true
      allow_pcmh_fee_type false
      requires_retrial_dates false
      requires_maat_reference true
      requires_cracked_dates false
      requires_trial_dates false
      roles %w[agfs lgfs]
      fee_type_code 'FXENP'
    end

    trait :contempt do
      name 'Contempt'
    end

    trait :appeal_against_conviction do
      name 'Appeal against conviction'
      is_fixed_fee true
      allow_pcmh_fee_type false
      requires_retrial_dates false
      requires_maat_reference true
      requires_cracked_dates false
      requires_trial_dates false
      roles %w[agfs lgfs]
      fee_type_code 'FXACV'
    end

    trait :guilty_plea do
      name 'Guilty plea'
      allow_pcmh_fee_type true
      requires_retrial_dates false
      roles %w[agfs lgfs]
      fee_type_code 'GRGLT'
    end

    trait :trial do
      name 'Trial'
      fee_type_code 'GRTRL'
      roles %w[agfs lgfs interim]
      allow_pcmh_fee_type true
      requires_trial_dates true
    end

    trait :retrial do
      name 'Retrial'
      fee_type_code 'GRRTR'
      roles %w[agfs lgfs interim]
      allow_pcmh_fee_type true
      requires_trial_dates true
      requires_retrial_dates true
    end

    trait :cracked_trial do
      name 'Cracked Trial'
      fee_type_code 'GRRAK'
      requires_cracked_dates true
      allow_pcmh_fee_type true
    end

    trait :cracked_before_retrial do
      name 'Cracked before retrial'
      fee_type_code 'GRCBR'
      requires_cracked_dates true
      allow_pcmh_fee_type true
    end

    trait :requires_maat_reference do
      requires_maat_reference true
    end

    trait :allow_pcmh_fee_type do
      allow_pcmh_fee_type true
    end

    trait :hsts do
      name 'Hearing subsequent to sentence'
      roles [ 'lgfs' ]
    end

    trait :cbr do
      name 'Breach of Crown Court order'
      fee_type_code 'FXCBR'
      requires_maat_reference false
      roles %w[agfs lgfs]
      is_fixed_fee  true
    end

    trait :grtrl do
      name 'Trial'
      fee_type_code 'GRTRL'
      allow_pcmh_fee_type true
      requires_trial_dates true
      roles %w[agfs lgfs interim]
    end
  end
end
