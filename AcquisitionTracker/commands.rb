require_relative 'indexes'

# Application Namespace
module AquisitionTracker
  # Methods that mutate the application's data
  module Commands
    def self.index_create_acquirer(facts, indexes = Indexes)
      # this command asserts attributes about a *new* aquirer
      id = facts.first.id
      attrs = { 'id' => id }
      attrs = attrs.merge Hash[
        *facts.map(&:attribute_name).zip(facts.map(&:value)).flatten
      ]
      # we convert these attibutes into a map and index them twice
      indexes[:entities][id] = attrs
      indexes[:aquirer_entities][id] = attrs
    end
    # module_function :index_create_acquirer

    def self.index_acquire_server(_facts, _indexes = Indexes)
      warn 'index_acquire_server not implemented'
      # 1. add all entities in indexes[:entities]
      # 2. add parts entities to indexes[:parts_entities]
      # 2. add aquisition entities to indexes[:aquisition_entities]
      # 2. add group entities to indexes[:aquisition_entities]
    end

    def self.index_deploy_server(_facts, _indexes = Indexes)
      warn 'index_deploy_server not implemented'
    end

    def self.index_acquire_part(_facts, _indexes = Indexes)
      warn 'index_acquire_part not implemented'
    end

    def self.index_repair_deployed_server(_facts, _indexes = Indexes)
      warn 'index_repair_deployed_server not implemented'
    end
  end
end
