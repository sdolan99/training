require_relative 'indexes'

# Application Namespace
module AcquisitionTracker
  # Methods that mutate the application's data
  module Commands
    # loads the journal into the indexes
    def self.hydrate(journal_entries)
      journal_entries.each do |journal_entry|
        command_name = journal_entry['command_name']
        facts = journal_entry['facts']
        Commands.send('index_' + command_name, facts)
      end
    end

    def self.index_create_acquirer(facts, indexes = Indexes) # rubocop:disable Metrics/AbcSize
      # this command asserts attributes about a *new* acquirer
      acquirer_ids = []
      facts.each do |(_operation, id, property, value)|
        indexes['entities'][id] ||= {}
        indexes['entities'][id]['id'] ||= id
        indexes['entities'][id][property] = value
        acquirer_ids << id if acquirer?(property)
      end

      acquirer_ids.each do |id|
        indexes['acquirer_entities'][id] = indexes['entities'][id]
      end
    end
    # module_function :index_create_acquirer

    def self.index_acquire_server(facts, indexes = Indexes) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # 2. add acquisition entities to indexes[:acquisition_entities]
      # 2. add group entities to indexes[:acquisition_entities]
      part_ids = []
      acquisition_ids = []
      group_ids = []
      facts.each do |(_operation, id, property, value)|
        indexes['entities'][id] ||= {}
        indexes['entities'][id]['id'] ||= id
        indexes['entities'][id][property] = value
        part_ids << id if part?(property)
        acquisition_ids << id if acquisition?(property)
        group_ids << id if group?(property)
      end

      part_ids.each do |id|
        indexes['part_entities'][id] = indexes['entities'][id]
      end

      acquisition_ids.each do |id|
        indexes['acquisition_entities'][id] = indexes['entities'][id]
      end
    end

    def self.index_deploy_server(facts, indexes = Indexes) # rubocop:disable Metrics/AbcSize
      deployment_ids = []
      facts.each do |(_operation, id, property, value)|
        indexes['entities'][id] ||= {}
        indexes['entities'][id]['id'] ||= id
        indexes['entities'][id][property] = value
        deployment_ids << id if deployment?(property)
      end

      deployment_ids.each do |id|
        indexes['deployment_entities'][id] = indexes['entities'][id]
      end
    end

    def self.index_acquire_part(facts, indexes = Indexes) # rubocop:disable Metrics/AbcSize
      acquisition_ids = []
      facts.each do |(_operation, id, property, value)|
        indexes['entities'][id] ||= {}
        indexes['entities'][id]['id'] ||= id
        indexes['entities'][id][property] = value
        acquisition_ids << id if acquisition?(property)
      end

      acquisition_ids.each do |id|
        indexes['acquisition_entities'][id] = indexes['entities'][id]
      end
    end

    def self.index_repair_deployed_server(facts, indexes = Indexes) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      repair_ids = []
      asserts(facts).each do |(_operation, id, property, value)|
        indexes['entities'][id] ||= {}
        indexes['entities'][id]['id'] ||= id
        indexes['entities'][id][property] = value
        repair_ids << id if repair?(property)
      end

      reverts(facts).each do |(_operation, id)|
        indexes.keys do |key|
          indexes[key].delete(id)
        end
      end

      repair_ids.each do |id|
        indexes['repair_entities'][id] = indexes['entities'][id]
      end
    end

    PARTS = %w(processor memory disk chassis)
    def self.part?(attribute_name, parts_list = PARTS)
      parts_list.include?(attribute_name.split('/')[0])
    end

    ACQUIRERS = %w(person)
    def self.acquirer?(attribute_name, acquirers_list = ACQUIRERS)
      acquirers_list.include?(attribute_name.split('/')[0])
    end

    def self.asserts(facts)
      facts.select { |fact| fact[0].eql?(':assert') }
    end

    def self.reverts(facts)
      facts.select { |fact| fact[0].eql?(':revert') }
    end

    def self.acquisition?(attribute_name)
      attribute_name.split('/')[0].eql?('acquisition')
    end

    def self.group?(attribute_name)
      attribute_name.split('/')[0].eql?('group')
    end

    def self.deployment?(attribute_name)
      attribute_name.split('/')[0].eql?('deployment')
    end

    def self.repair?(attribute_name)
      attribute_name.split('/')[0].eql?('repair')
    end
  end
end
