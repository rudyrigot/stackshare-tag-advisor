json.array!(@tags) do |tag|
  json.extract! tag, :id, :name, :api_id
  json.url tag_url(tag, format: :json)
end
