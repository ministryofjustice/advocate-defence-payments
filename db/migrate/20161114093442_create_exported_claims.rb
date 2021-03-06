class CreateExportedClaims < ActiveRecord::Migration[4.2]
  def change
    create_table :exported_claims do |t|
      t.references :claim, index: true, null: false
      t.uuid :claim_uuid, index: true, null: false
      t.string :status
      t.integer :status_code
      t.string :status_msg
      t.integer :retries, default: 0, null: false
      t.timestamps null: true
      t.datetime :published_at
      t.datetime :retried_at
    end
  end
end
