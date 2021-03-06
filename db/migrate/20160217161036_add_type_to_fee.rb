class AddTypeToFee < ActiveRecord::Migration[4.2]
  def up
    add_column :fees, :type, :string

    fees = ActiveRecord::Base.connection.execute("SELECT * FROM fees")
    fees.each do |fee|
      if fee['fee_type_id'].blank?
        raise "The fee record #{fee['id']} has no fee_type id."
      end
      fee_type = ActiveRecord::Base.connection.execute("SELECT * FROM fee_types WHERE id = #{fee['fee_type_id']}")[0]
      type = fee_type['type'].sub(/Type$/, '')
      ActiveRecord::Base.connection.execute("UPDATE fees SET type = '#{type}' WHERE id = #{fee['id']}")
    end
    
    Fee::BaseFeeType.connection.schema_cache.clear!
    Fee::BaseFeeType.reset_column_information
    
    Fee::BasicFeeType.connection.schema_cache.clear!
    Fee::BasicFeeType.reset_column_information
  end

  def down
    remove_column :fees, :type
  end
end
