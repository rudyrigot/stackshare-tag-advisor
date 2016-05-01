class AddFullObjectToStacks < ActiveRecord::Migration
  def change
    add_column :stacks, :full_object, :hstore
  end
end
