class Tool < ActiveRecord::Base
  belongs_to :layer

  validates :api_id, :name, :slug, :popularity, :layer_id, presence: true
  validates :api_id, uniqueness: true

  # Updates the DB so that the layers are the same as the ones in the API.
  def self.sync_from_stackshare_api
    stack_share_service = StackShareService.new

    # First, getting everything from the DB
    all_tools_from_db = Tool.all

    # Then, making as many lookup calls as there are layers, in order to accumulate all the tools with a layer
    all_tools_from_api = []
    Layer.pluck(:api_id).each do |layer_id|
      # Calling the API for just this page
      res = stack_share_service.call_api '/tools/lookup', layer_id: layer_id
      raise "Error when calling StackShare's API to fetch layers: #{res}" unless res.is_a?(Net::HTTPSuccess)
      all_tools_from_api += JSON.parse(res.body)
    end

    # Then, we want to modify the Hash from the API a bit, so that fields match exactly (like: ["layer"]["id"] becomes "layer_id")
    layers_by_api_id = Layer.all.group_by(&:api_id)  # Will be useful to turn a layer's api_id into its DB id
    all_tools_from_api.map!{|tool| {"id" => tool["id"], "name" => tool["name"], "slug" => tool["slug"], "popularity" => tool["popularity"], "layer_id" => layers_by_api_id[tool["layer"]["id"]].first.id, "full_object" => tool} }

    # Finally, syncing it all
    stack_share_service.sync_all(Tool, all_tools_from_db, all_tools_from_api, [:name, :slug, :popularity, :layer_id, :full_object])
  end
end
