require_relative 'validation'

module AcquisitionTracker
  module Ui
    # Manipulate journal entries and user input
    module Translate
      def self.write_new_add_part_entry(user_entry, parts_list)
        journal_entry = {
                          'timestamp' => Time.now,
                          'command_name' => 'acquire_part',
                          'facts' => part_entry_to_facts(user_entry, parts_list),
        }
        journal_entry
      end

      def self.write_new_add_server_entry(user_entry, parts_list)
        journal_entry = {
                          'timestamp' => Time.now,
                          'command_name' => 'acquire_server',
                          'facts' => user_entry_to_facts(user_entry, parts_list),
        }
        journal_entry
      end

      def self.read_user_entry(tmp_path)
        editor = ENV['EDITOR'] || 'vi'
        open_editor_command = "#{editor} #{tmp_path}"
        system(open_editor_command)
        user_entry_yaml = File.read(tmp_path)
        user_entry = YAML.load(user_entry_yaml)
        errors = Ui::Validation.add_server_data(user_entry)
        [errors, user_entry]
      end

      def self.read_user_add_part_entry(tmp_path)
        editor = ENV['EDITOR'] || 'vi'
        open_editor_command = "#{editor} #{tmp_path}"
        system(open_editor_command)
        user_entry_yaml = File.read(tmp_path)
        user_entry = YAML.load(user_entry_yaml)
        errors = Ui::Validation.add_part_user_data(user_entry)
        [errors, user_entry]
      end

      def self.part_entry_to_facts(user_entry, parts_list, randv = rand)
        facts = []

        if user_entry.key?('new_part')
          facts += new_part_fact(user_entry['new_part'], user_entry['date_acquired'], randv)
        else
          facts += existing_part_user_entry_to_fact(user_entry, parts_list)
        end
        facts
      end

      def self.existing_part_user_entry_to_fact(user_entry, parts_list, index = 1, randv = rand)
        facts = []
        full_part_ids = parts_list.map { |entity| entity['id'] }
        full_id = full_part_ids.detect { |fid| fid.start_with?(user_entry['existing_part_id']) }
        facts += part_id_to_fact(user_entry, full_id, index, randv, user_entry['date_acquired'])
        facts
      end

      def self.user_entry_to_facts(user_entry, parts_list, randv = rand)
        facts = []
        facts += user_new_parts_to_facts(user_entry, randv) if user_entry['new_parts']
        facts += user_included_parts_to_facts(user_entry, parts_list, randv) if user_entry['included_parts']
        part_ids = facts
                       .select { |fact| fact[2] == 'acquisition/part_id' }
                       .map { |fact| fact[3] }
                       .uniq
        group_fact = [
          ':assert',
          ":_server_#{randv}",
          'group/units',
          part_ids,
        ]
        facts << group_fact
        facts
      end

      def self.user_included_parts_to_facts(user_entry, parts_list, randv = rand)
        facts = []
        full_part_ids = parts_list.map { |entity| entity['id'] }
        user_entry['included_parts'].each.with_index do |ip, index|
          _, pid = ip.split('/')
          full_id = full_part_ids.detect { |fid| fid.start_with?(pid) }
          facts += part_id_to_fact(user_entry, full_id, index, randv)
        end
        facts
      end

      def self.part_id_to_fact(user_entry, full_id, indexv = rand, randv = rand, date_acquired = nil)
        facts = []
        acq_id = ":_acquisition_#{indexv}_#{randv}"
        time_fact = [
            ':assert',
            acq_id,
            'acquisition/timestamp',
            user_entry['date_acquired'] || date_acquired,
        ]
        part_id_fact = [
            ':assert',
            acq_id,
            'acquisition/part_id',
            full_id,
        ]
        acquirer_fact = [
                          ':assert',
                          acq_id,
                          'acquisition/acquirer',
                          ':_mike', # TODO: hardcoded
        ]
        facts << time_fact
        facts << part_id_fact
        facts << acquirer_fact
        facts
      end

      def self.user_new_parts_to_facts(user_entry, randv = rand)
        facts = []
        user_entry['new_parts'].each.with_index do |np, index|
          facts += new_part_fact(np, user_entry['date_acquired'], index, randv)
        end
        facts
      end

      def self.new_part_fact(new_part, date_acquired, indexv = rand, randv = rand)
        facts = []
        type = Translate.get_type(new_part)
        id = new_part["#{type}/temp_id"]
        temp_id = ":_#{type}_#{id}_#{randv}"
        new_part.each do |property, value|
          next if property.include?('temp_id')
          current_fact = [
                           ':assert',
                           temp_id,
                           property,
                           value,
          ]
          facts << current_fact
        end
        acq_id = ":_acquisition_#{indexv}_#{randv}"
        time_fact = [
          ':assert',
          acq_id,
          'acquisition/timestamp',
          date_acquired,
        ]
        part_id_fact = [
          ':assert',
          acq_id,
          'acquisition/part_id',
          temp_id,
        ]
        acquirer_fact = [
          ':assert',
          acq_id,
          'acquisition/acquirer',
          ':_mike',  # TODO: hardcoded
        ]
        facts << time_fact
        facts << part_id_fact
        facts << acquirer_fact
        facts
      end

      def self.get_type(attrs)
        attrs.keys.grep(%r{/}).first.split('/').first
      end
    end
  end
end
