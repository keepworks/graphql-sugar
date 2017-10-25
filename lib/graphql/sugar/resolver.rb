module GraphQL
  module Sugar
    module Resolver
      def call(obj, args, ctx)
        super

        resolve
      end
    end
  end
end
