require_relative 'validation'

module AcquisitionTracker
  module Ui
    # Manipulate journal entries and user input
    module Translate # rubocop:disable Metrics/ModuleLength
      def self.create_journal_entry(user_entry, parts_list, command)
        journal_entry = {
          'timestamp' => Time.now,
          'command_name' => command,
          'facts' => user_entry_to_facts(user_entry, parts_list),
        }
        journal_entry
      end
      def self.read_user_entry(tmp_path)
        user_entry = editor_entry(tmp_path)
        errors = Ui::Validation.add_server_data(user_entry)
        [errors, user_entry]
      end

      def self.read_user_add_part_entry(tmp_path)
        user_entry = editor_entry(tmp_path)
        errors = Ui::Validation.add_part_user_data(user_entry)
        [errors, user_entry]
      end

      def self.editor_entry(tmp_path)
        editor = ENV['EDITOR'] || 'vi'
        open_editor_command = "#{editor} #{tmp_path}"
        system(open_editor_command)
        user_entry_yaml = File.read(tmp_path)
        user_entry = YAML.load(user_entry_yaml)
        user_entry
      end

      # Validation of user_entry should already have been completed
      def self.part_entry_to_facts(user_entry, parts_list, randv = rand)
        facts = existing_part_user_entry_to_fact(user_entry, parts_list)
        facts += create_part_and_acquisition_facts(user_entry['new_part'], user_entry['date_acquired'], randv) if user_entry.key?('new_part')
        facts
      end

      # Parameters:
      #  Requires:
      #    user_entry - {
      #      'date_acquired' => '2016-03-18 14:08:43 -0700'
      #      'existing_part_id' => 'pa'
      #    }
      #    parts_list - [
      #      { 'id' => 'part1' }
      #    ]
      #    index = 1
      #    randv = 42
      #  returns: [
      #    [ ':assert', ':_acquisition_1_42', 'acquisition/timestamp', '2016-03-18 14:08:43 -0700' ]
      #    [ ':assert', ':_acquisition_1_42', 'acquisition/part_id', 'part1' ]
      #    [ ':assert', ':_acquisition_1_42', 'acquisition/acquirer, ':_mike' ]
      #   ]
      #
      def self.existing_part_user_entry_to_fact(user_entry, parts_list, index = 1, randv = rand)
        facts = []
        full_part_ids = parts_list.map { |entity| entity['id'] }
        full_id = full_part_ids.detect { |fid| fid.start_with?(user_entry['existing_part_id']) }
        facts += create_acquisition_facts(user_entry['date_acquired'], full_id, ':_mike', ":_acquisition_#{index}_#{randv}")
        facts
      end

      def self.user_entry_to_facts(user_entry, parts_list, randv = rand)
        facts = []
        facts += user_new_parts_to_facts(user_entry, randv) if user_entry['new_parts']
        facts += user_included_parts_to_facts(user_entry, parts_list, randv) if user_entry['included_parts']
        part_ids = uniq_part_ids(facts)
        id = ":_server_#{randv}"
        facts += create_assert_facts_from_attributes({ 'group/units' => part_ids}, id)
        facts
      end

      def self.user_included_parts_to_facts(user_entry, parts_list, randv = rand)
        facts = []
        full_part_ids = parts_list.map { |entity| entity['id'] }
        user_entry['included_parts'].each.with_index do |ip, index|
          _, pid = ip.split('/')
          full_id = full_part_ids.detect { |fid| fid.start_with?(pid) }
          facts += create_acquisition_facts(user_entry['date_acquired'], full_id, ':_mike', ":_acquisition_#{index}_#{randv}")
        end
        facts
      end

      # Parameters:
      #   requires:
      #     user_entry - {
      #      'date_acquired' => '2016-03-18 14:08:43 -0700',
      #     }
      #     'part_id' => 'abc123zz',
      #     'index' => 1
      #     'randv' => 1
      #  returns:
      #    [
      #      [ ":assert", ":_acquisition_1_1", "acquisition/timestamp", "2016-03-18 14:08:43 -070"],
      #      [ ":assert", ":_acquisition_1_1", "acquisition/part_id", "abc123zz"],
      #      [ ":assert", ":_acquisition_1_1", "acquisition/acquirer", ":_mike"]
      #   ]
      #
      def self.create_acquisition_facts_from_part_id(user_entry, part_id, indexv = rand, randv = rand, date_acquired = nil)
        create_acquisition_facts(user_entry['date_acquired'], part_id, ':_mike', ":_acquisition_#{indexv}_#{randv}")
      end

      def self.user_new_parts_to_facts(user_entry, randv = rand)
        facts = []
        user_entry['new_parts'].each.with_index do |np, index|
          facts += create_part_and_acquisition_facts(np, user_entry['date_acquired'], index, randv)
        end
        facts
      end

      # Parameters:
      #   requires:
      #     - new_part - {
      #       'parttype/temp_id' => 'temporaryid'
      #       'parttype/propert1' => 'dragon',
      #       'parttype/property2' => 'cat'
      #       }
      #
      #     - date_acquired - '2016-03-18 14:08:43 -0700'
      #     - index - 1
      #     - ranndv - 42
      #   returns:
      #     [
      #       [":assert", ":_parttype_temporaryid_42", "parttype/property1", "dragon"],
      #       [":assert", ":_parttype_temporaryid_42", "parttype/property2", "cat"],
      #       [ ':assert', ':_acquisition_1_42', 'acquisition/timestamp', '2016-03-18 14:08:43 -0700' ]
      #       [ ':assert', ':_acquisition_1_42', 'acquisition/part_id', ':_parttype_temporaryid_42 ]
      #       [ ':assert', ':_acquisition_1_42', 'acquisition/acquirer, ':_mike ]
      #     ]
      #
      def self.create_part_and_acquisition_facts(new_part, date_acquired, indexv = rand, randv = rand)
        type = Translate.get_type(new_part)
        temp_id_key = "#{type}/temp_id"
        temp_id_value = new_part.fetch(temp_id_key)
        temp_id = ":_#{type}_#{temp_id_value}_#{randv}"

        acq_id = ":_acquisition_#{indexv}_#{randv}"
        part_attributes = new_part.reject{|k, v| k == temp_id_key }

        create_assert_facts_from_attributes(part_attributes, temp_id) +
          create_acquisition_facts(date_acquired, temp_id, ':_mike', acq_id)
      end

      def self.create_acquisition_facts(date_acquired, part_id, acquirer, id)
        acquisition_attributes = {
            'acquisition/timestamp' => date_acquired,
            'acquisition/part_id' => part_id,
            'acquisition/acquirer' => acquirer,
        }
        create_assert_facts_from_attributes(acquisition_attributes, id)
      end

      def self.create_assert_facts_from_attributes(attributes, id)
        attributes.map { |property, value| [ ':assert', id, property, value ] }
      end

      def self.get_type(attrs)
        attrs.keys.grep(%r{/}).first.split('/').first
      end

      def self.uniq_part_ids(facts)
        facts
          .select { |fact| fact[2] == 'acquisition/part_id' }
          .map { |fact| fact[3] }
          .uniq
      end
    end
  end
end
