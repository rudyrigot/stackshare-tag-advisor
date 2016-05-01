class CreateStacksToolsAndStacksTagsJoinTables < ActiveRecord::Migration
  def change
    create_table :stacks_tools do |t|
      t.references :stack, index: true, foreign_key: true
      t.references :tool, index: true, foreign_key: true
    end
    create_table :stacks_tags do |t|
      t.references :stack, index: true, foreign_key: true
      t.references :tag, index: true, foreign_key: true
    end
  end
end
