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
