# == Schema Information
#
# Table name: offences
#
#  id               :integer          not null, primary key
#  description      :string
#  offence_class_id :integer
#  created_at       :datetime
#  updated_at       :datetime
#  unique_code      :string           default("anyoldrubbish"), not null
#

FactoryBot.define do
  factory :offence do
    offence_class { OffenceClass.first || create(:offence_class) }
    sequence(:description) { |n| "#{Faker::Lorem.sentence}-#{n}" }
    sequence(:unique_code) { |n| "ABCD-#{n}" }

    trait :miscellaneous do
      description { 'Miscellaneous/other' }
    end

    transient do
      lgfs_fee_scheme { false }
    end

    trait :with_fee_scheme do
      after(:build) do |offence, evaluator|
        fee_scheme = if evaluator.lgfs_fee_scheme
                       FeeScheme.find_by(name: 'LGFS', version: 9) || build(:fee_scheme, :lgfs)
                     else
                       FeeScheme.find_by(name: 'AGFS', version: 9) || build(:fee_scheme, :agfs_nine)
                     end
        offence.fee_schemes << fee_scheme
      end
    end

    trait :with_fee_scheme_nine do
      with_fee_scheme
    end

    trait :with_fee_scheme_ten do
      offence_class { nil }
      offence_band
      after(:build) do |offence|
        offence.fee_schemes << (FeeScheme.agfs.where(version: 10).first || build(:fee_scheme, :agfs_ten))
      end
    end

    trait :with_fee_scheme_eleven do
      offence_class { nil }
      offence_band
      after(:build) do |offence|
        offence.fee_schemes << (FeeScheme.agfs.where(version: 11).first || build(:fee_scheme, :agfs_eleven))
      end
    end

    trait :with_fee_scheme_twelve do
      offence_class { nil }
      offence_band
      after(:build) do |offence|
        offence.fee_schemes << (FeeScheme.agfs.where(version: 12).first || build(:fee_scheme, :agfs_twelve))
      end
    end
  end
end
