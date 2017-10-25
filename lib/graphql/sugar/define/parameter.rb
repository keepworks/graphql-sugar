module GraphQL
  module Sugar
    module Define
      module Parameter
        def self.call(type_defn, name, type = nil, *args, **kwargs, &block) # rubocop:disable Metrics/ParameterLists
          model_class = type_defn.metadata[:model_class]

          type ||= kwargs[:type]

          if type.nil?
            column_name = Sugar.get_column_name(name)
            type = Sugar.get_graphql_type(model_class, column_name, enforce_non_null: false)
          end

          if kwargs[:as].nil?
            field_name = name.to_s.underscore.to_sym
            field_name = "#{field_name}_attributes".to_sym if model_class && model_class.nested_attributes_options[field_name]
            kwargs[:as] = field_name
          end

          GraphQL::Define::AssignArgument.call(type_defn, name, type, *args, **kwargs, &block)
        end
      end
    end
  end
end
