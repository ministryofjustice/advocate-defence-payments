# == Schema Information
#
# Table name: fees
#
#  id                    :integer          not null, primary key
#  claim_id              :integer
#  fee_type_id           :integer
#  quantity              :integer
#  amount                :decimal(, )
#  created_at            :datetime
#  updated_at            :datetime
#  uuid                  :uuid
#  rate                  :decimal(, )
#  type                  :string
#  warrant_issued_date   :date
#  warrant_executed_date :date
#

class Fee::GraduatedFee < Fee::BaseFee

  belongs_to :fee_type, class_name: Fee::GraduatedFeeType

  validates_with Fee::GraduatedFeeValidator

  delegate :first_day_of_trial, :actual_trial_length, :requires_trial_dates, to: :claim, allow_nil: true

  def is_graduated?
    true
  end

end
