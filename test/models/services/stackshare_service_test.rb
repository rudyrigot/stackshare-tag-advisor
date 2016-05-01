require 'test_helper'

class StackShareServiceTest < ActiveSupport::TestCase

  setup do
    # Stubbing the /stacks/tags requests
    page_1_json = JSON.dump([{"id":1,"name":"saas"},{"id":2,"name":"cloud-computing"},{"id":3,"name":"paas"},{"id":4,"name":"big-data"}])
    stub_request(:get, "https://api.stackshare.io/v1/stacks/tags?access_token=#{Rails.configuration.x.stackshare_api_access_token}&page=1").to_return(body: page_1_json)
    page_2_json = JSON.dump([{"id":5,"name":"ventures-for-good"},{"id":6,"name":"consumer-lending"},{"id":7,"name":"finance-technology"},{"id":8,"name":"social-media"}])
    stub_request(:get, "https://api.stackshare.io/v1/stacks/tags?access_token=#{Rails.configuration.x.stackshare_api_access_token}&page=2").to_return(body: page_2_json)
    stub_request(:get, "https://api.stackshare.io/v1/stacks/tags?access_token=#{Rails.configuration.x.stackshare_api_access_token}&page=3").to_return(status: 404)
  end

  test "all_tags_from_page" do
    expected = [{"id"=>1, "name"=>"saas"}, {"id"=>2, "name"=>"cloud-computing"}, {"id"=>3, "name"=>"paas"}, {"id"=>4, "name"=>"big-data"}, {"id"=>5, "name"=>"ventures-for-good"}, {"id"=>6, "name"=>"consumer-lending"}, {"id"=>7, "name"=>"finance-technology"}, {"id"=>8, "name"=>"social-media"}]
    assert_equal expected, StackShareService.new.all_tags_from_page(1)
  end

  test "sync_all_tags!" do
    StackShareService.new.sync_all_tags!

    expected = ["saas", "cloud-computing", "paas", "big-data", "ventures-for-good", "consumer-lending", "finance-technology", "social-media"]
    assert_equal expected, Tag.order(:api_id).pluck(:name)
  end

end
