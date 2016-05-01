json.array!(@layers) do |layer|
  json.extract! layer, :id, :api_id, :name, :slug
  json.url layer_url(layer, format: :json)
end
