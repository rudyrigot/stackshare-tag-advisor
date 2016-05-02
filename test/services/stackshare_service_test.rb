require 'test_helper'

class StackShareServiceTest < ActiveSupport::TestCase

  # The lack of test on call_api is voluntary: the method is tiny and unlikely to fail, and it is used
  # extensively by other methods that are heavily tested.

  test "object_from_api_id" do
    sss = StackShareService.new
    assert_equal 'cloud', sss.object_from_api_id(Tag, 2).name
    assert_equal 'new_thing', sss.object_from_api_id(Tag, 9).name
    assert_nil sss.object_from_api_id(Tag, 999)

    assert_equal 'cloud', StackShareService.new.object_from_api_id(Tag, 2, Tag.all).name
  end

  test "sync_all" do
    # Stubbing a /tools/layers requests
    layers_page_json = %([{"id":1,"name":"Application and Data","slug":"application_and_data"},{"id":2,"name":"Utilities","slug":"utilities"},{"id":3,"name":"DevOps","slug":"devops"},{"id":4,"name":"Business Tools","slug":"business_tools"}])
    stub_request(:get, "https://api.stackshare.io/v1/tools/layers?access_token=").to_return(body: layers_page_json)

    sss = StackShareService.new
    sss.sync_all(Layer, Layer.all, JSON.parse(sss.call_api('/tools/layers').body), [:name, :slug])

    expected = ["application_and_data", "utilities", "devops", "business_tools"]
    assert_equal expected, Layer.order(:api_id).pluck(:slug)
  end

end
