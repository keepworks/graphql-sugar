module GraphQL
  module Sugar
    module Define
      module Relationships
        def self.call(type_defn, *field_names)
          model_class = Sugar.get_model_class(type_defn)

          if field_names.count == 0
            [:belongs_to, :has_one, :has_many].each do |macro|
              model_class.reflect_on_all_associations(macro).each do |association|
                field_names << association.name
              end
            end
          end

          field_names.each do |field_name|
            Sugar::Define::Relationship.call(type_defn, field_name)
          end
        end
      end
    end
  end
end
