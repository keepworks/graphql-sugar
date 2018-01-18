module GraphQL
  module Sugar
    module Define
      module Relationship
        def self.call(type_defn, field_name)
          model_class = Sugar.get_model_class(type_defn)
          association_name = Sugar.get_association_name(field_name)
          association = model_class.reflect_on_association(association_name)

          if association.association_class == ActiveRecord::Associations::BelongsToAssociation
            define_belongs_to(type_defn, field_name, model_class, association_name, association)
          elsif association.association_class == ActiveRecord::Associations::HasOneAssociation ||
                association.association_class == ActiveRecord::Associations::HasManyAssociation ||
                association.association_class == ActiveRecord::Associations::HasManyThroughAssociation
            define_has_one_or_many(type_defn, field_name, model_class, association_name, association)
          end
        end

        def self.define_belongs_to(type_defn, field_name, model_class, association_name, association)
          key_field_name = association.foreign_key.to_s.camelize(:lower).to_sym
          key_type = GraphQL::ID_TYPE
          key_property = association.foreign_key.to_sym

          type = "Types::#{association.klass}Type".constantize
          property = association_name.to_sym

          key_column_details = Sugar.get_column_details(model_class, association.foreign_key)
          is_not_null = !key_column_details.null || Sugar.validates_presence?(model_class, association_name)

          if is_not_null
            key_type = key_type.to_non_null_type
            type = type.to_non_null_type
          end

          GraphQL::Define::AssignObjectField.call(type_defn, key_field_name, type: key_type, property: key_property)
          GraphQL::Define::AssignObjectField.call(type_defn, field_name, type: type, property: property)
        end

        def self.define_has_one_or_many(type_defn, field_name, _model_class, association_name, association)
          kwargs = {}

          kwargs[:type] = "Types::#{association.klass}Type".constantize

          if association.association_class == ActiveRecord::Associations::HasManyAssociation ||
            association.association_class == ActiveRecord::Associations::HasManyThroughAssociation
            kwargs[:type] = kwargs[:type].to_non_null_type.to_list_type
          end

          begin
            function_class = Sugar.get_resolver_function(field_name)
            kwargs[:function] ||= function_class.new
            kwargs[:resolve] ||= ->(obj, args, ctx) { function_class.new.call(obj, args, ctx) }
          rescue
            kwargs[:property] = association_name.to_sym
          end

          GraphQL::Define::AssignObjectField.call(type_defn, field_name, **kwargs)
        end
      end
    end
  end
end
