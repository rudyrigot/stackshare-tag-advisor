# Allows to organize communication with the StackShare API
class StackShareService

  API_ROOT = 'https://api.stackshare.io/v1'

  def initialize
    @access_token = Rails.configuration.x.stackshare_api_access_token
  end

  # Updates the DB so that the tags are the same as the ones in the API.
  # Is mindful of DB query: 1 to look everything up, and 1 per update or new insert.
  # Updates are incremental, so that users' experiences are not disrupted during the update.
  def sync_all_tags!
    # First, getting everything from both datasources
    all_tags_from_db = Tag.all
    all_tags_from_api = all_tags_from_page(1)

    # Destroying all tags that shouldn't be there
    api_ids_to_delete = all_tags_from_db.map(&:api_id) - all_tags_from_api.map{|tag| tag["id"]}
    Tag.where(api_id: api_ids_to_delete).destroy_all

    # And for all tags that should be there, either inserting or updating
    all_tags_from_db_by_id = all_tags_from_db.group_by(&:api_id)
    all_tags_from_api.each do |tag|
      if all_tags_from_db_by_id.has_key?(tag["id"])  # Already exists, just needs to be potentially updated
        all_tags_from_db_by_id[tag["id"]].first.update!(name: tag["name"])
      else  # Doesn't exist, needs to be created
        Tag.create!(api_id: tag["id"], name: tag["name"])
      end
    end
  end

  # Recursive function to return all tags of all pages from a certain page number
  #
  # @param [FixNum] page the page number where to start
  # @return [Array<Hash>] all the existing tags in one array
  def all_tags_from_page(page)
    # Calling the API for just this page
    uri = URI(API_ROOT + '/stacks/tags')
    uri.query = URI.encode_www_form(access_token: @access_token, page: page)
    res = Net::HTTP.get_response(uri)

    if res.is_a?(Net::HTTPNotFound)  # This happens for the page after the last one -> base case
      []
    elsif res.is_a?(Net::HTTPSuccess)  # This is an existing page -> recursion
      JSON.parse(res.body) + all_tags_from_page(page+1)
    else
      raise "Error when calling StackShare's API: #{res}"
    end
  end

end
