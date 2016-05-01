# Allows to organize communication with the StackShare API
class StackShareService

  API_ROOT = 'https://api.stackshare.io/v1'

  def initialize
    @access_token = Rails.configuration.x.stackshare_api_access_token

    # An index of type Hash<class,Hash<FixNum,Model>>, that will, for a given model class
    # and a given api_id, allow to return the matching object without having to call the DB every time.
    # Is tied to the instance of the service so that it gets renewed across syncs.
    @objects_by_api_id_by_model_class = {}
  end


  ## TAGS

  # Updates the DB so that the tags are the same as the ones in the API.
  def sync_all_tags!
    # First, getting everything from both datasources
    all_tags_from_db = Tag.all
    all_tags_from_api = all_tags_from_page(1)

    sync_all!(Tag, all_tags_from_db, all_tags_from_api)
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
      raise "Error when calling StackShare's API to fetch pages: #{res}"
    end
  end


  ## LAYERS

  # Updates the DB so that the layers are the same as the ones in the API.
  def sync_all_layers!
    # First, getting everything from the DB
    all_layers_from_db = Layer.all

    # Calling the API
    uri = URI(API_ROOT + '/tools/layers')
    uri.query = URI.encode_www_form access_token: @access_token
    res = Net::HTTP.get_response(uri)
    raise "Error when calling StackShare's API to fetch layers: #{res}" unless res.is_a?(Net::HTTPSuccess)
    all_layers_from_api = JSON.parse(res.body)

    sync_all!(Layer, all_layers_from_db, all_layers_from_api, [:name, :slug])
  end


  ## TOOLS

  # Updates the DB so that the layers are the same as the ones in the API.
  def sync_all_tools!
    # First, getting everything from the DB
    all_tools_from_db = Tool.all

    # Then, making as many lookup calls as there are layers, in order to accumulate all the tools with a layer
    all_tools_from_api = []
    Layer.pluck(:api_id).each do |layer_id|
      # Calling the API for just this page
      uri = URI(API_ROOT + '/tools/lookup')
      uri.query = URI.encode_www_form access_token: @access_token, layer_id: layer_id
      res = Net::HTTP.get_response(uri)
      raise "Error when calling StackShare's API to fetch layers: #{res}" unless res.is_a?(Net::HTTPSuccess)
      all_tools_from_api += JSON.parse(res.body)
    end

    # Then, we want to modify the Hash from the API a bit, so that fields match exactly (like: ["layer"]["id"] becomes "layer_id")
    layers_by_api_id = Layer.all.group_by(&:api_id)  # Will be useful to turn a layer's api_id into its DB id
    all_tools_from_api.map!{|tool| {"id" => tool["id"], "name" => tool["name"], "slug" => tool["slug"], "popularity" => tool["popularity"], "layer_id" => layers_by_api_id[tool["layer"]["id"]].first.id} }

    # Finally, syncing it all
    sync_all!(Tool, all_tools_from_db, all_tools_from_api, [:name, :slug, :popularity, :layer_id])
  end


  private


  ## USED FOR ALL SYNCS

  # Given a model class and an API id, returns the matching object from DB. Returns nil if such object doesn't exist.
  # We could have used model_class.find_by(api_id: api_id), but this operation is done countless times in a row during a sync,
  # for each object to insert or update. Better to just create a Hash that will index things from one DB call.
  #
  # Sometimes, you already have the result of the DB query before calling this, if so, you can pass it as the collection
  # parameter and not even need to call the DB; if you don't pass one, the DB will be queried.
  #
  # @param [Model] model_class the model class that we need to look in
  # @param [FixNum] api_id the api_id to look up
  # @param [Array<Model>] collection the collection of all objects of that type in DB, if you have it (otherwise DB will be queried)
  def object_from_api_id(model_class, api_id, collection = nil)
    # Fetching all objects of the model, if no collection parameter
    collection ||= model_class.all
    # Building the index, if didn't exist yet
    unless @objects_by_api_id_by_model_class.has_key? model_class
      @objects_by_api_id_by_model_class[model_class] = Hash[collection.map{|item| [item.api_id, item] }]
    end
    # Lookup
    @objects_by_api_id_by_model_class[model_class][api_id]
  end

  # Syncs up all objects in a DB based on those fetched from the API.
  # Updates are incremental, so that users' experiences are not disrupted during the update.
  #
  # @param [class] model_class the model class that should be used to perform ActiveRecord operations
  # @param [Array<Model>] all_from_db all of those objects as they currently are in the DB
  # @param [Array<Hash>] all_from_api all of those objects as fetched from the API
  # @param [Array<Symbol>] fields the fields that must be synced up, besides api_id
  def sync_all!(model_class, all_from_db, all_from_api, fields = [:name])
    # Destroying all records that shouldn't be there
    api_ids_to_delete = all_from_db.map(&:api_id) - all_from_api.map{|tag| tag["id"]}
    model_class.where(api_id: api_ids_to_delete).destroy_all

    # And for all records that should be there, either inserting or updating
    all_from_api.each do |record|
      object_in_db = object_from_api_id(model_class, record["id"], all_from_db)
      if object_in_db.present?  # Already exists, just needs to be potentially updated
        object_in_db.update!(Hash[fields.map{|f|[f, record[f.to_s]]}])
      else  # Doesn't exist, needs to be created
        object_hash = {api_id: record["id"]}
        fields.each{|f| object_hash[f] = record[f.to_s] }
        model_class.create!(object_hash)
      end
    end
  end

end
