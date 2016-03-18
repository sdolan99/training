module AcquisitionTracker
  module Ui
    # Validations for user input
    module Validation
      # TODO: Make better validation
      def self.add_server_data(server_data)
        errors = []
        if server_data['new_parts'].nil? && server_data['included_parts'].nil?
          errors << ['Server must have parts']
        end
        errors
      end

      def self.add_part_user_data(part_data)
        # TODO: Validate if part already exists
        errors = []
        if part_data['existing_part_id'].nil? && part_data['new_part'].nil?
          errors << ['New or existing part must be chosen']
        end

        if !part_data['existing_part_id'].nil? && !part_data['new_part'].nil?
          errors << ['Only a new or existing part must be chosen, not both']
        end
        errors
      end

      def self.strip_namespaces_from_keys(map)
        map.reduce({}) do |ac, (k, v)|
          ac.merge(k.split('/').last => v)
        end
      end
    end
  end
end
