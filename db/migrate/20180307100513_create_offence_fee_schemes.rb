class CreateOffenceFeeSchemes < ActiveRecord::Migration[4.2]
  def change
    create_table :offence_fee_schemes do |t|
      t.references :offence, index: true
      t.references :fee_scheme, index: true
    end
  end
end
