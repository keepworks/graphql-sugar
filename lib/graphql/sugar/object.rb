module GraphQL
  module Sugar
    module Object
      COMMON_ATTRIBUTES = [:id, :created_at, :updated_at]

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def inherited(klass)
          derived_model_class = klass.name.demodulize.gsub('Type', '').safe_constantize
          klass.instance_variable_set(:@model_class, derived_model_class)
          klass.instance_variable_set(:@attributes_initialized, Set.new)
        end

        def model_class(model_class)
          @model_class = model_class
          initialize_common_attributes unless all_initial_attributes_added?
        end

        def initialize_common_attributes
          COMMON_ATTRIBUTES.each do |_attribute|
            @attributes_initialized.add(_attribute)
            attribute(_attribute)
          end
        end

        def attribute(name, return_type_expr = nil, desc = nil, **kwargs, &block)
          raise "You must define a `model_class` first in `#{self.name}`." if @model_class.blank?

          initialize_common_attributes if @attributes_initialized.exclude?(name) && !all_initial_attributes_added?
          @attributes_initialized.add(name)

          if return_type_expr.nil?
            return_type_expr = Sugar.get_graphql_type(@model_class, name.to_s)

            # Set null
            kwargs[:null] = !return_type_expr.non_null? if kwargs[:null].nil?

            # Unwrap
            return_type_expr = return_type_expr.of_type if return_type_expr.non_null?
          end

          field(name, return_type_expr, desc, **kwargs, &block)
        end

        def all_initial_attributes_added?
          COMMON_ATTRIBUTES.all? do |attribute|
            @attributes_initialized.include?(attribute)
          end
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

          association_type = "#{association.klass}"
          type = "Types::#{association_type.gsub('::', '')}Type".constantize
          property = association_name.to_sym

          key_column_details = Sugar.get_column_details(@model_class, association.foreign_key)
          is_null = key_column_details.null || !Sugar.validates_presence?(@model_class, association_name)

          field(key_field_name, key_type, null: is_null)
          field(field_name, type, null: is_null)
        end

        def define_has_one_or_many(field_name, association_name, association)
          association_type = "#{association.klass}"
          type = "Types::#{association_type.gsub('::', '')}Type".constantize
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
