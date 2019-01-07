GraphQL::DATETIME_TYPE = GraphQL::ScalarType.define do
  name 'DateTime'
  description 'An ISO 8601-encoded datetime'

  coerce_input ->(value, _ctx) { Time.zone.parse(value) rescue nil }
  coerce_result ->(value, _ctx) { value.utc.iso8601 }
end
