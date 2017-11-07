module GraphQL
  module Sugar
    module Define
      module Resolver
        def self.call(type_defn, field_name, type_or_field = nil, desc = nil, **kwargs, &block) # rubocop:disable Metrics/ParameterLists
          type_or_field ||= kwargs[:type] if !kwargs[:type].nil?

          if type_or_field.nil?
            # Automatically determine type
            type_or_field ||= Sugar.get_resolver_graphql_type(field_name)

            # Automatically determine if plural, modify type to !types[Type] if true
            plural = kwargs[:plural]
            plural = Sugar.get_resolver_plural(field_name) if plural.nil?
            type_or_field = type_or_field.to_list_type.to_non_null_type if plural
          end

          # Automatically determine function
          function_class = Sugar.get_resolver_function(field_name)
          kwargs[:function] ||= function_class.new
          kwargs[:resolve] ||= ->(obj, args, ctx) { function_class.new.call(obj, args, ctx) }

          GraphQL::Define::AssignObjectField.call(type_defn, field_name, type_or_field, desc, **kwargs, &block)
        end
      end
    end
  end
end
