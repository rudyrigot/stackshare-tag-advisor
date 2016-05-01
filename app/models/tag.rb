class Tag < ActiveRecord::Base
  validates :api_id, :name, presence: true
end
