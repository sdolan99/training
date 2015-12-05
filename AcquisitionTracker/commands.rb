require_relative 'indexes'

# Application Namespace
module AquisitionTracker
  # Methods that mutate the application's data
  module Commands
    def self.index_create_acquirer(facts, indexes = Indexes)
      # this command asserts attributes about a *new* aquirer
      return
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

    def self.index_acquire_server(facts, indexes = Indexes)
      # 2. add aquisition entities to indexes[:aquisition_entities]
      # 2. add group entities to indexes[:aquisition_entities]
      require 'pp'
      pp facts
      part_ids = []
      acquisition_ids = []
      facts.each do |(_operation, id, property, value)|
        indexes['entities'][id] ||= {}
        indexes['entities'][id]['id'] ||= id
        indexes['entities'][id][property] = value
        part_ids << id if is_part?(property)
        acquisition_ids << id if is_acquisition?(property)
      end

      part_ids.each do |id|
        indexes['parts_entities'][id] = indexes['entities'][id]
      end
      acquisition_ids.each do |id|
        indexes['acquisition_entities'][id] = indexes['entities'][id]
      end
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

    Parts = ['processor', 'memory', 'disk', 'chassis']
    def self.is_part?(attribute_name, parts_list = Parts)
      Parts.include?(attribute_name.split('/')[0])
    end

    def self.is_acquisition?(attribute_name)
      attribute_name.split('/')[0].eql?('acquisition')
    end
  end
end
