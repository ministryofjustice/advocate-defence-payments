class CreateDocuments < ActiveRecord::Migration[4.2]
  def change
    create_table :documents do |t|
      t.references :claim, index: true
      t.references :document_type, index: true
      t.text :notes
      t.string :document

      t.timestamps null: true
    end
  end
end
