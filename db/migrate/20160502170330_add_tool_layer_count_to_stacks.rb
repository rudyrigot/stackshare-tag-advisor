class AddToolLayerCountToStacks < ActiveRecord::Migration
  def change
    add_column :stacks, :tool_layer_count, :integer
  end
end
