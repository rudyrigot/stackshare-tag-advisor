require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  setup do
    @tag = tags(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tags)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tag" do
    assert_difference('Tag.count') do
      post :create, tag: { api_id: 999, name: @tag.name }
    end

    assert_redirected_to tag_path(assigns(:tag))
  end

  test "should show tag" do
    get :show, id: @tag
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @tag
    assert_response :success
  end

  test "should update tag" do
    patch :update, id: @tag, tag: { api_id: @tag.api_id, name: @tag.name }
    assert_redirected_to tag_path(assigns(:tag))
  end

  test "should destroy tag" do
    assert_difference('Tag.count', -1) do
      delete :destroy, id: @tag
    end

    assert_redirected_to tags_path
  end

  test "should get most_popular_stack" do
    # Stubbing the /stacks/lookup requests
    stacks_json = %([{"id":2,"name":"Alphabet","slug":"alphabet","popularity":170,"company":{"description":"","location":""},"tools":[{"id":2681},{"id":2},{"id":999}],"tags":[{"id":1},{"id":999}]},{"id":3,"name":"Holberton School","slug":"holberton-school","popularity":4,"tools":[{"id":2681},{"id":2}],"tags":[{"id":1}]},{"id":3,"name":"Apple","slug":"apple","popularity":4,"tools":[{"id":2681}],"tags":[{"id":1}]}])
    stub_request(:get, "https://api.stackshare.io/v1/stacks/lookup?access_token=&tag_id=1").to_return(body: stacks_json)

    # Putting some JSON data in tools
    tools(:one).update! full_object: %({"image_url":"","tag_line":""})
    tools(:two).update! full_object: %({"image_url":"","tag_line":""})

    get :most_popular_stack, id: tags(:three)
    assert_response :success
  end

  test "should get most_popular_tools" do
    # Putting some JSON data in tools
    tools(:one).update! full_object: %({"image_url":"","tag_line":""})
    tools(:two).update! full_object: %({"image_url":"","tag_line":""})
    tools(:three).update! full_object: %({"image_url":"","tag_line":""})

    get :most_popular_tools, id: tags(:three)
    assert_response :success
  end
end
