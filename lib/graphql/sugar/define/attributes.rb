module GraphQL
  module Sugar
    module Define
      module Attributes
        def self.call(type_defn, *field_names)
          model_class = Sugar.get_model_class(type_defn)

          field_names = model_class.columns_hash.keys.map(&:to_sym) if field_names.count == 0
          field_names.each do |field_name|
            Sugar::Define::Attribute.call(type_defn, field_name)
          end
        end
      end
    end
  end
end
