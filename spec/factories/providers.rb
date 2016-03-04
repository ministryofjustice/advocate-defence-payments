# == Schema Information
#
# Table name: providers
#
#  id              :integer          not null, primary key
#  name            :string
#  supplier_number :string
#  provider_type   :string
#  vat_registered  :boolean
#  uuid            :uuid
#  api_key         :uuid
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  roles           :string
#

FactoryGirl.define do
  factory :provider do
    provider_type 'chamber'

    # NOTE: factory used for demo data and should therefore provide name that can be used to identify it for destruction if necessary
    #       see ClaimDestroyer
    sequence(:name) { |n| "#{Faker::Company.name} (Test-Provider-#{n})" }

    roles ['agfs']

    trait :agfs do
      provider_type 'chamber'
      roles ['agfs']
    end

    trait :lgfs do
      provider_type 'firm'
      sequence(:supplier_number) { |n| "#{n}-#{Time.now.to_i}" }
      roles ['lgfs']
    end

    trait :agfs_lgfs do
      provider_type 'firm'
      sequence(:supplier_number) { |n| "#{n}-#{Time.now.to_i}" }
      roles ['agfs', 'lgfs']
    end

    # requires supplier number
    trait :firm do
      provider_type 'firm'
      sequence(:supplier_number) { |n| "#{n}-#{Time.now.to_i}" }
      vat_registered { true }
    end

    # does not require supplier number
    trait :chamber do
      provider_type 'chamber'
      supplier_number nil
    end

  end
end
