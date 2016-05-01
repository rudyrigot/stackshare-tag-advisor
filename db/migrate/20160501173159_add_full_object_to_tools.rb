class AddFullObjectToTools < ActiveRecord::Migration
  def change
    add_column :tools, :full_object, :hstore
  end
end
