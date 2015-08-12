# == Schema Information
#
# Table name: chambers
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  account_number :string(255)
#  vat_registered :boolean
#  created_at     :datetime
#  updated_at     :datetime
#  uuid           :uuid
#

require 'rails_helper'

RSpec.describe Chamber, type: :model do
  it { should have_many(:advocates) }
  it { should have_many(:claims) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of(:account_number) }
  it { should validate_uniqueness_of(:account_number) }
end
