require 'test_helper'

class TagTest < ActiveSupport::TestCase

  setup do
    # Stubbing the /stacks/tags requests
    tags_page_1_json = %([{"id":1,"name":"saas"},{"id":2,"name":"cloud-computing"},{"id":3,"name":"paas"},{"id":4,"name":"big-data"}])
    stub_request(:get, "https://api.stackshare.io/v1/stacks/tags?access_token=&page=1").to_return(body: tags_page_1_json)
    tags_page_2_json = %([{"id":5,"name":"ventures-for-good"},{"id":6,"name":"consumer-lending"},{"id":7,"name":"finance-technology"},{"id":8,"name":"social-media"}])
    stub_request(:get, "https://api.stackshare.io/v1/stacks/tags?access_token=&page=2").to_return(body: tags_page_2_json)
    stub_request(:get, "https://api.stackshare.io/v1/stacks/tags?access_token=&page=3").to_return(status: 404)
  end

  test "sync_from_stackshare_api" do
    Tag.sync_from_stackshare_api
    expected = ["saas", "cloud-computing", "paas", "big-data", "ventures-for-good", "consumer-lending", "finance-technology", "social-media"]
    assert_equal expected, Tag.order(:api_id).pluck(:name)
  end

  test "api_fetch_all_tags_from_page" do
    expected = [{"id"=>1, "name"=>"saas"}, {"id"=>2, "name"=>"cloud-computing"}, {"id"=>3, "name"=>"paas"}, {"id"=>4, "name"=>"big-data"}, {"id"=>5, "name"=>"ventures-for-good"}, {"id"=>6, "name"=>"consumer-lending"}, {"id"=>7, "name"=>"finance-technology"}, {"id"=>8, "name"=>"social-media"}]
    assert_equal expected, Tag.api_fetch_all_tags_from_page(1, StackShareService.new)
  end

  test "most_popular_tools" do
    assert_equal ['punch'], tags(:one).most_popular_tools.map(&:slug)
    assert_equal [], tags(:two).most_popular_tools.map(&:slug)
    assert_equal ['punch','foo'], tags(:three).most_popular_tools.map(&:slug)
    stacks(:two).update!(tools: [tools(:two)])
    assert_equal ['foo','punch'], tags(:three).most_popular_tools.map(&:slug)

    stacks(:one).update! verified: false
    assert_equal ['foo','punch'], tags(:three).most_popular_tools(true).map(&:slug)
    assert_equal ['foo'], tags(:three).most_popular_tools.map(&:slug)
  end

  test "most_popular_full_stack" do
    assert_equal 'google', tags(:one).most_popular_full_stack.slug
    assert_nil tags(:two).most_popular_full_stack
    assert_equal 'stackshare', tags(:three).most_popular_full_stack.slug
    stacks(:one).destroy # stackshare
    assert_equal 'google', tags(:three).most_popular_full_stack.slug
    stacks(:two).destroy # google
    assert_equal 'facebook', tags(:one).most_popular_full_stack.slug
    assert_nil tags(:three).most_popular_full_stack
  end
end
