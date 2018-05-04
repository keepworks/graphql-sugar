module GraphQL
  module Sugar
    module Mutation
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def mutator(name, *args)
          @mutators ||= {}
          @mutators[name] = args
        end

        def to_graphql
          obj_type = super

          @mutators.each do |name, args|
            GraphQL::Sugar::Define::Mutator.call(obj_type, name, *args)
          end

          obj_type
        end
      end
    end
  end
end
