module Graphql
  class MutatorGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def create_mutator
      template 'mutator.erb', File.join('app/graphql/mutators', class_path, "#{file_name}_mutator.rb")
    end
  end
end
