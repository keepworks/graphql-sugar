require 'graphql/sugar/version'

module GraphQL
  module Sugar
    GRAPHQL_TYPE_MAPPING = {
      integer: GraphQL::INT_TYPE,
      float: GraphQL::FLOAT_TYPE,
      decimal: GraphQL::FLOAT_TYPE,
      boolean: GraphQL::BOOLEAN_TYPE,
      string: GraphQL::STRING_TYPE
    }.freeze

    def self.get_resolver_graphql_type(field_name)
      "Types::#{field_name.to_s.classify}Type".constantize
    end

    def self.get_resolver_function(field_name)
      "#{field_name.to_s.camelize}Resolver".constantize
    end

    def self.get_resolver_plural(field_name)
      field_string = field_name.to_s
      field_string.pluralize == field_string
    end

    def self.get_mutator_function(field_name)
      "#{field_name.to_s.camelize}Mutator".constantize
    end

    def self.get_model_class(type_defn)
      model_class = type_defn.metadata[:model_class]
      raise "You must define a `model_class` first in `#{type_defn.class}`." if model_class.blank?
      model_class
    end

    def self.get_column_name(field_name)
      field_name.to_s.underscore
    end

    def self.get_column_details(model_class, column_name)
      column_details = model_class.columns_hash[column_name]
      raise "The attribute '#{column_name}' doesn't exist in model '#{model_class}'." if column_details.blank?
      column_details
    end

    def self.get_graphql_type(model_class, column_name, enforce_non_null: true) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return GraphQL::ID_TYPE.to_non_null_type if column_name == model_class.primary_key

      column_details = get_column_details(model_class, column_name)

      belongs_to_association = model_class.reflect_on_all_associations(:belongs_to).find { |a| a.foreign_key == column_name }

      type = if model_class.defined_enums.key?(column_name)
               GraphQL::STRING_TYPE
             elsif belongs_to_association.present?
               GraphQL::ID_TYPE
             else
               GRAPHQL_TYPE_MAPPING[column_details.type] || GraphQL::STRING_TYPE
             end

      type = type.to_list_type if column_details.array?

      if enforce_non_null
        is_not_null = !column_details.null
        is_not_null ||= Sugar.validates_presence?(model_class, column_name)
        is_not_null ||= Sugar.validates_presence?(model_class, belongs_to_association.name) if belongs_to_association.present?
        type = type.to_non_null_type if is_not_null
      end

      type
    end

    def self.get_association_name(field_name)
      field_name.to_s.underscore
    end

    def self.validates_presence?(model_class, column_name)
      column_validators = model_class.validators_on(column_name)
      column_validators.any? do |validator|
        validator.class == ActiveRecord::Validations::PresenceValidator &&
          !validator.options[:allow_nil] &&
          !validator.options[:allow_blank] &&
          !validator.options.key?(:if) &&
          !validator.options.key?(:unless)
      end
    end
  end
end

require 'graphql/sugar/define/resolver'
require 'graphql/sugar/define/mutator'
require 'graphql/sugar/define/model_class'
require 'graphql/sugar/define/attribute'
require 'graphql/sugar/define/attributes'
require 'graphql/sugar/define/relationship'
require 'graphql/sugar/define/relationships'
require 'graphql/sugar/define/parameter'
require 'graphql/sugar/object'
require 'graphql/sugar/function'
require 'graphql/sugar/resolver'
require 'graphql/sugar/mutator'
require 'graphql/sugar/query'
require 'graphql/sugar/mutation'
require 'graphql/sugar/boot'
