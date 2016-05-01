class CreateLayers < ActiveRecord::Migration
  def change
    create_table :layers do |t|
      t.integer :api_id
      t.string :name
      t.string :slug

      t.timestamps null: false
    end
  end
end
