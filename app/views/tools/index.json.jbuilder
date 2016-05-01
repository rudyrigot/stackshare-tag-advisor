json.array!(@tools) do |tool|
  json.extract! tool, :id, :layer_id, :api_id, :name, :slug, :popularity
  json.url tool_url(tool, format: :json)
end
