class Stack < ActiveRecord::Base
  has_and_belongs_to_many :tools
  has_and_belongs_to_many :tags

  validates :api_id, :name, :slug, :popularity, presence: true
  validates :api_id, uniqueness: true

  # Updates the DB so that the layers are the same as the ones in the API.
  def self.sync_from_stackshare_api(tag_id)
    stack_share_service = StackShareService.new

    # First, getting everything from the DB
    all_stacks_from_db = Stack.all

    # Then, making as many lookup calls as there are layers, in order to accumulate all the tools with a layer
    all_stacks_from_api = []
    # Calling the API for just this page
    res = stack_share_service.call_api '/stacks/lookup', tag_id: tag_id
    raise "Error when calling StackShare's API to fetch layers: #{res}" unless res.is_a?(Net::HTTPSuccess)
    all_stacks_from_api += JSON.parse(res.body)

    # Then, we want to modify the Hash from the API a bit, so that fields match exactly (like the tools and tags fields)
    # TODO use the nice method
    all_stacks_from_api.map! do |stack|
      {
        "id" => stack["id"],
        "name" => stack["name"],
        "slug" => stack["slug"],
        "popularity" => stack["popularity"],
        "full_object" => stack
      }
    end

    # Finally, syncing it all
    stack_share_service.sync_all(Stack, all_stacks_from_db, all_stacks_from_api, [:name, :slug, :popularity, :full_object])
  end
end
