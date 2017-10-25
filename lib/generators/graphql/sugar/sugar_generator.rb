module Graphql
  class SugarGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def add_paths
      application { 'config.eager_load_paths += Dir["#{config.root}/app/graphql/functions/**/"]' }
      application { 'config.eager_load_paths += Dir["#{config.root}/app/graphql/mutators/**/"]' }
      application { 'config.eager_load_paths += Dir["#{config.root}/app/graphql/resolvers/**/"]' }
    end

    def create_application_files
      template 'application_function.erb', 'app/graphql/functions/application_function.rb'
      template 'application_resolver.erb', 'app/graphql/resolvers/application_resolver.rb'
      template 'application_mutator.erb', 'app/graphql/mutators/application_mutator.rb'
    end
  end
end
