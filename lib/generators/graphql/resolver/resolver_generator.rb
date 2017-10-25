module Graphql
  class ResolverGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def create_resolver
      template 'resolver.erb', File.join('app/graphql/resolvers', class_path, "#{file_name}_resolver.rb")
    end
  end
end
