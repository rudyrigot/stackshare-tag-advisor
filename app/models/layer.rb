class Layer < ActiveRecord::Base
  has_many :tools, dependent: :destroy

  validates :api_id, :name, :slug, presence: true
  validates :api_id, uniqueness: true

  # Syncs up layers from the StackShare API
  def self.sync_from_stackshare_api
    stack_share_service = StackShareService.new

    # First, getting everything from the DB
    all_layers_from_db = Layer.all

    # Calling the API
    res = stack_share_service.call_api '/tools/layers'
    raise "Error when calling StackShare's API to fetch layers: #{res}" unless res.is_a?(Net::HTTPSuccess)
    all_layers_from_api = JSON.parse(res.body)

    # Syncing
    stack_share_service.sync_all!(Layer, all_layers_from_db, all_layers_from_api, [:name, :slug])
  end
end
