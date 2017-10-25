module GraphQL
  module Sugar
    module Define
      module ModelClass
        def self.call(type_defn, model_class, type_name = nil)
          type_defn.name = type_name || model_class.to_s
          type_defn.metadata[:model_class] = model_class

          common_field_names = [:id, :createdAt, :updatedAt]
          common_field_names.each do |common_field_name|
            begin
              Sugar::Define::Attribute.call(type_defn, common_field_name)
            rescue => e
              Rails.logger.warn e
            end
          end
        end
      end
    end
  end
end
