module GraphQL
  module Sugar
    module Query
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def resolver(name, *args)
          @resolvers ||= {}
          @resolvers[name] = args
        end

        def to_graphql
          obj_type = super

          @resolvers.each do |name, args|
            GraphQL::Sugar::Define::Resolver.call(obj_type, name, *args)
          end

          obj_type
        end
      end
    end
  end
end
