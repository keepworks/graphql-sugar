GraphQL::ObjectType.accepts_definitions(
  resolver: GraphQL::Sugar::Define::Resolver,
  mutator: GraphQL::Sugar::Define::Mutator,
  model_class: GraphQL::Sugar::Define::ModelClass,
  attribute: GraphQL::Sugar::Define::Attribute,
  attributes: GraphQL::Sugar::Define::Attributes,
  relationship: GraphQL::Sugar::Define::Relationship,
  relationships: GraphQL::Sugar::Define::Relationships
)

GraphQL::Field.accepts_definitions(
  parameter: GraphQL::Sugar::Define::Parameter
)

GraphQL::InputObjectType.accepts_definitions(
  model_class: GraphQL::Define.assign_metadata_key(:model_class),
  parameter: GraphQL::Sugar::Define::Parameter
)
