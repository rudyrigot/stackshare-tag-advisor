require 'test_helper'

class StackShareServiceTest < ActiveSupport::TestCase

  test "object_from_api_id" do
    sss = StackShareService.new
    assert_equal 'cloud', sss.send(:object_from_api_id, Tag, 2).name
    assert_equal 'new_thing', sss.send(:object_from_api_id, Tag, 9).name

    assert_equal 'cloud', StackShareService.new.send(:object_from_api_id, Tag, 2, Tag.all).name
  end

end
