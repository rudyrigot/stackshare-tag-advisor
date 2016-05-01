class Stack < ActiveRecord::Base
  validates :api_id, :name, :slug, :popularity, presence: true
  validates :api_id, uniqueness: true
end
