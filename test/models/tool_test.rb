require 'test_helper'

class ToolTest < ActiveSupport::TestCase
  setup do
    # Stubbing the /tools/lookup requests
    tools_1_json = %([{"id":2681,"name":"Punchtime for Trello","slug":"punchtime","popularity":1,"layer":{"id":1}},{"id":3262,"name":"Phoenix Framework","slug":"phoenix","popularity":3,"layer":{"id":1}}])
    stub_request(:get, "https://api.stackshare.io/v1/tools/lookup?access_token=&layer_id=1").to_return(body: tools_1_json)
    tools_2_json = %([{"id":2682,"name":"Punchtime2 for Trello","slug":"punchtime2","popularity":3,"layer":{"id":2}}])
    stub_request(:get, "https://api.stackshare.io/v1/tools/lookup?access_token=&layer_id=2").to_return(body: tools_2_json)
  end

  test "sync_from_stackshare_api" do
    Tool.sync_from_stackshare_api
    expected = ["punchtime", "punchtime2", "phoenix"]
    assert_equal expected, Tool.order(:api_id).pluck(:slug)
    expected = ["application", "utilities", "application"]
    assert_equal expected, Tool.order(:api_id).map{|t|t.layer.slug}
  end
end
