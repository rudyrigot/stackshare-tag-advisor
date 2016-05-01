class Tag < ActiveRecord::Base
  validates :api_id, :name, presence: true
  validates :api_id, uniqueness: true
end
