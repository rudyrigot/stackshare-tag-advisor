class CreateTools < ActiveRecord::Migration
  def change
    create_table :tools do |t|
      t.references :layer, index: true, foreign_key: true
      t.integer :api_id
      t.string :name
      t.string :slug
      t.integer :popularity

      t.timestamps null: false
    end
  end
end
