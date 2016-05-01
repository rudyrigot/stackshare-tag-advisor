class CreateStacks < ActiveRecord::Migration
  def change
    create_table :stacks do |t|
      t.integer :api_id
      t.string :name
      t.string :slug
      t.integer :popularity

      t.timestamps null: false
    end
  end
end
