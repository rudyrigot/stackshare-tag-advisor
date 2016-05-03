class Tag < ActiveRecord::Base
  has_and_belongs_to_many :stacks

  validates :api_id, :name, presence: true
  validates :api_id, uniqueness: true

  # Syncs up tags from the StackShare API
  def self.sync_from_stackshare_api
    stack_share_service = StackShareService.new
    # First, getting everything from both datasources
    all_tags_from_db = Tag.all
    all_tags_from_api = api_fetch_all_tags_from_page(1, stack_share_service)
    # Then, we want to modify the Hash from the API a bit, so that fields match exactly (like: "humanized_name")
    all_tags_from_api.map! do |tag|
      {
        "id" => tag["id"],
        "name" => tag["name"],
        "humanized_name" => tag["name"].gsub("-", " ").split.map(&:capitalize).join(' ')
      }
    end
    # Then syncing
    stack_share_service.sync_all(Tag, all_tags_from_db, all_tags_from_api, [:name, :humanized_name])
  end

  # Recursive function to return all tags of all pages from a certain page number
  #
  # @param [FixNum] page the page number where to start
  # @return [Array<Hash>] all the existing tags in one array
  def self.api_fetch_all_tags_from_page(page, stack_share_service)
    # Calling the API for just this page
    res = stack_share_service.call_api '/stacks/tags', page: page

    if res.is_a?(Net::HTTPNotFound)  # This happens for the page after the last one -> base case
      []
    elsif res.is_a?(Net::HTTPSuccess)  # This is an existing page -> recursion
      JSON.parse(res.body) + api_fetch_all_tags_from_page(page+1, stack_share_service)
    else
      raise "Error when calling StackShare's API to fetch pages: #{res}"
    end
  end

  # Will build a list of the tools by order of popularity for the current tag, on verified stacks.
  #
  # @param [Boolean] include_not_verified also include stacks that are not verified
  # @return [Array<Tool>] most popular tools in order
  def most_popular_tools(include_not_verified= false)
    # First, we're building a hash { id_tool => accumulated_score }
    accumulated_scores = Hash.new(0)
    Stack.includes(:tools).joins(:tags).where('tags.id = ?', self.id).where(verified: include_not_verified ? [true, false] : true).find_each do |stack|
      stack.tool_ids.each do |tool_id|
        accumulated_scores[tool_id] += 1
      end
    end
    # Winning some time if there's no result
    return [] if accumulated_scores.empty?
    # Then, reverse-sorting this hash, and returning its keys, to get the IDs in order
    tool_ids = accumulated_scores.sort_by{|_,value| value}.reverse.map(&:first)
    # We could query each Tool, and the code would look good, but we should really group these queries into one
    tools_by_id = Tool.where(id: tool_ids).group_by(&:id)
    tool_ids.map{|id| tools_by_id[id].first}
  end

  # For the current tag, finds the most popular stack with the highest possible number of layers.
  #
  # @return [Stack]
  def most_popular_full_stack
    most_popular_stack_closest_to(Layer.count)
  end

  private

  # Recursive function to find the most popular stack of the current tag with a number of tool layers, but if there
  # is no such stack, will look successively in stacks with less layers.
  #
  # @param [FixNum] nb_layers the number of layers to look at currently
  # @return [Stack,nil] either the Stack, ot nil if there's none regardless of number of layers
  def most_popular_stack_closest_to(nb_layers)
    stacks = Stack.joins(:tags).order(popularity: :desc).where('tags.id = ?', self.id).where(tool_layer_count: nb_layers).limit(1)
    if nb_layers == -1
      nil
    elsif stacks.empty?
      most_popular_stack_closest_to(nb_layers - 1)
    else
      stacks.first
    end
  end

end
