json.array!(@stacks) do |stack|
  json.extract! stack, :id, :api_id, :name, :slug, :popularity
  json.url stack_url(stack, format: :json)
end
