class Stack < ActiveRecord::Base
  has_and_belongs_to_many :tools
  has_and_belongs_to_many :tags

  validates :api_id, :name, :slug, :popularity, presence: true
  validates :api_id, uniqueness: true

  # Syncs up stacks from the StackShare API
  def self.sync_from_stackshare_api(tag_id)
    stack_share_service = StackShareService.new

    # First, getting everything from the DB
    all_stacks_from_db = Stack.joins(:tags).where("tags.id = ?", stack_share_service.object_from_api_id(Tag, tag_id))

    # Calling the API for just this page
    res = stack_share_service.call_api '/stacks/lookup', tag_id: tag_id
    raise "Error when calling StackShare's API to fetch stacks: #{res}" unless res.is_a?(Net::HTTPSuccess)
    all_stacks_from_api = JSON.parse(res.body)

    # Then, we want to modify the Hash from the API a bit, so that fields match exactly (like the tools and tags fields, and populate the full field)
    all_layer_ids = Layer.order(:id).pluck(:id)
    all_stacks_from_api.map! { |stack|
      tools = stack["tools"].map{ |t| stack_share_service.object_from_api_id(Tool, t["id"]) }.compact
      if Tool.full?(tools, all_layer_ids)  # Only storing stacks that are full (has at least one tool of each layer)
        {
          "id" => stack["id"],
          "name" => stack["name"],
          "slug" => stack["slug"],
          "popularity" => stack["popularity"],
          "tools" => tools,
          "tags" => stack["tags"].map{|t|stack_share_service.object_from_api_id(Tag, t["id"])}.compact,
          "full_object" => stack
        }
      else
        nil
      end
    }.compact!

    # Finally, syncing it all
    stack_share_service.sync_all(Stack, all_stacks_from_db, all_stacks_from_api, [:name, :slug, :popularity, :tools, :tags, :full_object])
  end
end
