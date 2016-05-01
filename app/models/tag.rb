class Tag < ActiveRecord::Base
  validates :api_id, :name, presence: true
  validates :api_id, uniqueness: true

  # Syncs up tags from the StackShare API
  def self.sync_from_stackshare_api
    stack_share_service = StackShareService.new
    # First, getting everything from both datasources
    all_tags_from_db = Tag.all
    all_tags_from_api = api_fetch_all_tags_from_page(1, stack_share_service)
    # Then syncing
    stack_share_service.sync_all(Tag, all_tags_from_db, all_tags_from_api)
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
end
