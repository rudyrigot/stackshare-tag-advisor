class AddHumanizedNameToTags < ActiveRecord::Migration
  def change
    add_column :tags, :humanized_name, :string
  end
end
