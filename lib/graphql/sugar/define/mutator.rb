module GraphQL
  module Sugar
    module Define
      module Mutator
        def self.call(type_defn, field_name, type_or_field = nil, desc = nil, **kwargs, &block) # rubocop:disable Metrics/ParameterLists
          # Automatically determine function
          function_class = Sugar.get_mutator_function(field_name)
          kwargs[:function] ||= function_class.new
          kwargs[:resolve] ||= ->(obj, args, ctx) { function_class.new.call(obj, args, ctx) }

          GraphQL::Define::AssignObjectField.call(type_defn, field_name, type_or_field, desc, **kwargs, &block)
        end
      end
    end
  end
end
