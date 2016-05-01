class Layer < ActiveRecord::Base
  validates :api_id, :name, :slug, presence: true
end
