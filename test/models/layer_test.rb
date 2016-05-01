require 'test_helper'

class LayerTest < ActiveSupport::TestCase
  setup do
    # Stubbing the /tools/layers requests
    layers_page_json = %([{"id":1,"name":"Application and Data","slug":"application_and_data"},{"id":2,"name":"Utilities","slug":"utilities"},{"id":3,"name":"DevOps","slug":"devops"},{"id":4,"name":"Business Tools","slug":"business_tools"}])
    stub_request(:get, "https://api.stackshare.io/v1/tools/layers?access_token=").to_return(body: layers_page_json)
  end

  test "sync_from_stackshare_api" do
    Layer.sync_from_stackshare_api
    expected = ["application_and_data", "utilities", "devops", "business_tools"]
    assert_equal expected, Layer.order(:api_id).pluck(:slug)
  end
end
