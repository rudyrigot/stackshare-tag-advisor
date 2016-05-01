class AddFullObjectToTools < ActiveRecord::Migration
  def change
    enable_extension "hstore"
    add_column :tools, :full_object, :hstore
  end
end
