module GraphQL
  module Sugar
    module Object
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def model_class(model_class)
          @model_class = model_class

          common_attribute_names = [:id, :created_at, :updated_at]
          common_attribute_names.each(&method(:attribute))
        end

        def attribute(name, return_type_expr = nil, desc = nil, **kwargs, &block)
          raise "You must define a `model_class` first in `#{self.name}`." if @model_class.blank?

          if return_type_expr.nil?
            return_type_expr = Sugar.get_graphql_type(@model_class, name.to_s)

            # Set null
            kwargs[:null] = !return_type_expr.non_null? if kwargs[:null].nil?

            # Unwrap
            return_type_expr = return_type_expr.of_type if return_type_expr.non_null?
          end

          field(name, return_type_expr, desc, **kwargs, &block)
        end

        def attributes(*names)
          names.each(&method(:attribute))
        end

        def relationship(name)
          association_name = Sugar.get_association_name(name)
          association = @model_class.reflect_on_association(association_name)

          if association.association_class == ActiveRecord::Associations::BelongsToAssociation
            define_belongs_to(name, association_name, association)
          elsif association.association_class == ActiveRecord::Associations::HasOneAssociation ||
                association.association_class == ActiveRecord::Associations::HasManyAssociation ||
                association.association_class == ActiveRecord::Associations::HasManyThroughAssociation
            define_has_one_or_many(name, association_name, association)
          end
        end

        def relationships(*names)
          names.each(&method(:relationship))
        end

        def define_belongs_to(field_name, association_name, association)
          key_field_name = association.foreign_key.to_s.camelize(:lower).to_sym
          key_type = GraphQL::ID_TYPE
          key_property = association.foreign_key.to_sym

          type = "Types::#{association.klass}Type".constantize
          property = association_name.to_sym

          key_column_details = Sugar.get_column_details(@model_class, association.foreign_key)
          is_null = key_column_details.null || !Sugar.validates_presence?(@model_class, association_name)

          field(key_field_name, key_type, null: is_null)
          field(field_name, type, null: is_null)
        end

        def define_has_one_or_many(field_name, association_name, association)
          type = "Types::#{association.klass}Type".constantize
          is_null = true

          if association.association_class == ActiveRecord::Associations::HasManyAssociation ||
            association.association_class == ActiveRecord::Associations::HasManyThroughAssociation
            type = [type] # null: false is default
            is_null = false
          end

          kwargs = {}

          begin
            function_class = Sugar.get_resolver_function(field_name)
            kwargs[:function] ||= function_class.new
            kwargs[:resolve] ||= ->(obj, args, ctx) { function_class.new.call(obj, args, ctx) }
          rescue NameError
            nil
          end

          field(field_name, type, null: is_null, **kwargs)
        end
      end
    end
  end
end
