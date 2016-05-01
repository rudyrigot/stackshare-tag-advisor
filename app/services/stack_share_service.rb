# Allows to organize communication with the StackShare API
class StackShareService

  API_ROOT = 'https://api.stackshare.io/v1'

  def initialize
    @access_token = Rails.configuration.x.stackshare_api_access_token
  end

  def sync_all_tags!
    # TODO
  end

  # Recursive function to return all tags of all pages from a certain page number
  #
  # @param [FixNum] page the page number where to start
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
