class ModifyFeeTypeCalculatedData < ActiveRecord::Migration[4.2]
  def up
    Fee::BasicFeeType.where(code: ['PPE','NPW']).each do |record|
      record.update_column(:calculated, false)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
