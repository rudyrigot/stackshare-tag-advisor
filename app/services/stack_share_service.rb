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


  # A one-size-fits-all method to call the API. Returns the response object, because depending on endpoints,
  # we will have to check out the status code sometimes.
  #
  # @param [String] path the path of the endpoint, without the domain and api version (like "/tools/lookup")
  # @param [Hash<Symbol,String>] params the HTTP params
  # @return [Response] the HTTP response object
  def call_api(path, params = {})
    params[:access_token] = @access_token
    uri = URI(API_ROOT + path)
    uri.query = URI.encode_www_form params
    Net::HTTP.get_response(uri)
  end


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
  def sync_all(model_class, all_from_db, all_from_api, fields = [:name])
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
