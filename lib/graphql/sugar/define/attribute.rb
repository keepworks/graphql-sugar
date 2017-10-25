module GraphQL
  module Sugar
    module Define
      module Attribute
        def self.call(type_defn, field_name, type_or_field = nil, desc = nil, **kwargs, &block) # rubocop:disable Metrics/ParameterLists
          model_class = Sugar.get_model_class(type_defn)
          column_name = Sugar.get_column_name(field_name)

          type_or_field ||= kwargs[:type] if !kwargs[:type].nil?
          type_or_field ||= Sugar.get_graphql_type(model_class, column_name)

          kwargs[:property] ||= column_name.to_sym if kwargs[:resolve].nil?

          GraphQL::Define::AssignObjectField.call(type_defn, field_name, type_or_field, desc, **kwargs, &block)
        end
      end
    end
  end
end
