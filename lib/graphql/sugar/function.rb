module GraphQL
  module Sugar
    module Function
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          attr_reader :object
          attr_reader :params
          attr_reader :context
        end
      end

      module ClassMethods
        # Workaround:
        # A `GraphQL::Function` is supposed to be a 'reusable container for field logic'.
        # However, extended Field DSL (specified using `GraphQL::Field.accepts_definitions(...)`)
        # is not available within Functions. Therefore, re-defining it here.
        def parameter(name, *args, **kwargs, &block)
          computed_type = GRAPHQL_TYPE_MAPPING[args.first]
          computed_type = GraphQL::ID_TYPE if name == :id

          null_argument     = !!!kwargs.delete(:null)     # reverting nil to false and then to true
          required_argument = !!kwargs.delete(:required)  # reverting nil to false
          computed_type     = computed_type.to_non_null_type if required_argument || null_argument

          args[0] = computed_type
          kwargs[:as] ||= name.to_s.underscore.to_sym
          argument(name, *args, **kwargs, &block)
        end
      end

      def call(obj, args, ctx)
        @object = obj
        @params = args.to_h.deep_symbolize_keys
        @context = ctx
      end
    end
  end
end
