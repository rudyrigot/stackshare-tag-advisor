class Tool < ActiveRecord::Base
  belongs_to :layer
  has_and_belongs_to_many :stacks

  validates :api_id, :name, :slug, :popularity, :layer_id, presence: true
  validates :api_id, uniqueness: true

  # Syncs up tools from the StackShare API
  def self.sync_from_stackshare_api
    stack_share_service = StackShareService.new

    # First, getting everything from the DB
    all_tools_from_db = Tool.all

    # Then, making as many lookup calls as there are tools, in order to accumulate all the tools with a layer
    all_tools_from_api = []
    Layer.pluck(:api_id).each do |layer_id|
      # Calling the API for just this page
      res = stack_share_service.call_api '/tools/lookup', layer_id: layer_id
      raise "Error when calling StackShare's API to fetch tools: #{res}" unless res.is_a?(Net::HTTPSuccess)
      all_tools_from_api += JSON.parse(res.body)
    end

    # Then, we want to modify the Hash from the API a bit, so that fields match exactly (like: ["layer"]["id"] becomes "layer_id")
    all_tools_from_api.map! do |tool|
      {
        "id" => tool["id"],
        "name" => tool["name"],
        "slug" => tool["slug"],
        "popularity" => tool["popularity"],
        "layer" => stack_share_service.object_from_api_id(Layer, tool["layer"]["id"]),
        "full_object" => tool
      }
    end

    # Finally, syncing it all
    stack_share_service.sync_all(Tool, all_tools_from_db, all_tools_from_api, [:name, :slug, :popularity, :layer, :full_object])
  end
end
