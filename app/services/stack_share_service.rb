# Allows to organize communication with the StackShare API
class StackShareService

  API_ROOT = 'https://api.stackshare.io/v1'

  def initialize
    @access_token = Rails.configuration.x.stackshare_api_access_token
  end


  # Syncs up all objects in a DB based on those fetched from the API.
  # Updates are incremental, so that users' experiences are not disrupted during the update.
  #
  # @param [class] model_class the model class that should be used to perform ActiveRecord operations
  # @param [Array<Model>] all_from_db all of those objects as they currently are in the DB
  # @param [Array<Hash>] all_from_api all of those objects as fetched from the API
  def self.sync_all!(model_class, all_from_db, all_from_api)
    # Destroying all records that shouldn't be there
    api_ids_to_delete = all_from_db.map(&:api_id) - all_from_api.map{|tag| tag["id"]}
    model_class.where(api_id: api_ids_to_delete).destroy_all

    # And for all records that should be there, either inserting or updating
    all_from_db_by_id = all_from_db.group_by(&:api_id)
    all_from_api.each do |record|
      if all_from_db_by_id.has_key?(record["id"])  # Already exists, just needs to be potentially updated
        all_from_db_by_id[record["id"]].first.update!(name: record["name"])
      else  # Doesn't exist, needs to be created
        model_class.create!(api_id: record["id"], name: record["name"])
      end
    end
  end


  ## TAGS

  # Updates the DB so that the tags are the same as the ones in the API.
  def sync_all_tags!
    # First, getting everything from both datasources
    all_tags_from_db = Tag.all
    all_tags_from_api = all_tags_from_page(1)

    StackShareService.sync_all!(Tag, all_tags_from_db, all_tags_from_api)
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
