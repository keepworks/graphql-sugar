module GraphQL
  module Sugar
    module Mutator
      def call(obj, args, ctx)
        super

        mutate
      end
    end
  end
end
