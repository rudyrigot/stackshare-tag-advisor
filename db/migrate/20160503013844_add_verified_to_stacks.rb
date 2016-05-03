class AddVerifiedToStacks < ActiveRecord::Migration
  def change
    add_column :stacks, :verified, :boolean, default: false, null: false
  end
end
