class Tool < ActiveRecord::Base
  belongs_to :layer

  validates :api_id, :name, :slug, :popularity, :layer_id, presence: true
  validates :api_id, uniqueness: true
end
