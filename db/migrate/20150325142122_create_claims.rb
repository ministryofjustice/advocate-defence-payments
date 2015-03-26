class CreateClaims < ActiveRecord::Migration
  def change
    create_table :claims do |t|
      t.text :additional_information
      t.references :advocate, index: true

      t.timestamps
    end
  end
end
