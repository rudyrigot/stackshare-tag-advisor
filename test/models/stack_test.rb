require 'test_helper'

class StackTest < ActiveSupport::TestCase
  setup do
    # Stubbing the /stacks/lookup requests
    stacks_json = %([{"id":2,"name":"Alphabet","slug":"alphabet","popularity":170},{"id":3,"name":"Holberton School","slug":"holberton-school","popularity":4}])
    stub_request(:get, "https://api.stackshare.io/v1/stacks/lookup?access_token=&tag_id=1").to_return(body: stacks_json)
  end

  test "sync_from_stackshare_api" do
    Stack.sync_from_stackshare_api(1)
    expected = ["alphabet", "holberton-school"]
    assert_equal expected, Stack.order(:api_id).pluck(:slug)
  end
end
