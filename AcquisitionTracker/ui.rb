require_relative './read_journal'
require_relative './queries'
require_relative './write_journal'

module AcquisitionTracker
  # UI functions for printing data
  module Ui
    def self.inventory_status_report(data, outstream = $stdout)
      min_quantity = data['min_quantity']
      outstream.puts 'Inventory Status Report'
      outstream.puts " Min quantity: #{min_quantity}"
      outstream.puts ''
      outstream.puts 'Quantity  Type'

      data.each do |i, p|
        next if i == 'min_quantity'
        type = get_type(p['properties'])
        outstream.puts "#{p['count']} / #{min_quantity}   -  #{type}"
      end
    end

    def self.add_server(parts_list)
      # Generate yaml in temp file to open in users text edit
      # Returns, read context of file and parse/perform command
      parts_list_string = parts_list(parts_list)
      user_yaml = <<EOY
# add server
# -- Parts list
#{parts_list_string.map { |l| " # - #{l.strip}" }.join("\n")}

# Does the Server need any parts not in the above list?
new_parts:
  # - processor/temp_id: 1
  #   processor/model_number: Model-21A
  #   processor/speed: 10
  #   processor/wattage: 80
  # - memory/temp_id: 2
  #   memory/model_number: hpram13-25
  #   memory/type: dram
  #   memory/capacity_gb: 34

# What Parts is the Server made from?
included_parts:
  # - processor/xxxxxx
  # - memory/xxxxxxx
  # ...

# What date was it acquired?
date_acquired: #{Time.now.to_s.split(' ').first}
EOY
      tmp_dir = ENV['TMPDIR'] || '/tmp'
      tmp_filename = 'ac-addserver.yaml'
      tmp_path = File.join(tmp_dir, tmp_filename)
      File.write(tmp_path, user_yaml)
      errors, user_entry = read_user_entry(tmp_path)
      user_entry.nil?
      until errors.empty?
        puts errors
        puts 'Press enter to continue correcting errors.'
        $stdin.gets
        user_entry, errors = read_user_entry(tmp_path)
      end
      puts 'No errors detected'
      add_server_entry = write_new_add_server_entry(user_entry, parts_list)
      JournalWriter.entry(add_server_entry)
    end

    def self.write_new_add_server_entry(user_entry, parts_list)
      journal_entry = {
        'timestamp' => Time.now,
        'command_name' => 'acquire_server',
        'facts' => translate_user_entry_to_facts(user_entry, parts_list),
      }
      journal_entry
    end

    def self.translate_part_entry_to_facts(user_entry, parts_list, randv = rand)
      facts = []
      if user_entry.key?('new_part')
        facts += translate_user_new_parts_to_facts(user_entry, randv)
      else
        facts += translate_acquire_part_to_facts(user_entry, parts_list, randv)
      end
      facts
    end


    def self.translate_user_entry_to_facts(user_entry, parts_list, randv = rand)
      facts = []
      facts += translate_user_new_parts_to_facts(user_entry, randv) if user_entry['new_parts']
      facts += translate_user_included_parts_to_facts(user_entry, parts_list, randv) if user_entry['included_parts']
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

    def self.translate_user_included_parts_to_facts(user_entry, parts_list, randv = rand)
      facts = []
      full_part_ids = parts_list.map { |entity| entity['id'] }
      user_entry['included_parts'].each.with_index do |ip, index|
        _, pid = ip.split('/')
        facts += translate_part_id_to_fact(user_entry, pid, parts_list, full_part_ids, index, randv)
      end
      facts
    end

    def self.translate_part_id_to_fact(user_entry, part_id, parts_list, full_part_ids, indexv = rand, randv = rand)
      facts = []
      full_id = full_part_ids.detect { |fid| fid.start_with?(part_id) }
      acq_id = ":_acquisition_#{indexv}_#{randv}"
      time_fact = [
        ':assert',
        acq_id,
        'acquisition/timestamp',
        user_entry['date_acquired'],
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
        ':_mike',  # TODO: hardcoded
      ]
      facts << time_fact
      facts << part_id_fact
      facts << acquirer_fact
      facts
    end

    def self.translate_user_new_parts_to_facts(user_entry, randv = rand)
      facts = []
      user_entry['new_parts'].each.with_index do |np, index|
        facts += translate_acquire_part_to_fact(np, user_entry['date_acquired'], index, randv)
      end
      facts
    end

    def self.translate_acquire_part_to_fact(new_part, date_acquired, indexv = randv, randv = rand)
      facts = []
      type = get_type(new_part)
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

    def self.read_user_entry(tmp_path)
      editor = ENV['EDITOR'] || 'vi'
      open_editor_command = "#{editor} #{tmp_path}"
      system(open_editor_command)
      user_entry_yaml = File.read(tmp_path)
      user_entry = YAML.load(user_entry_yaml)
      errors = validate_add_server_data(user_entry)
      [errors, user_entry]
    end

    # TODO: Make better validation
    def self.validate_add_server_data(server_data)
      errors = []
      if server_data['new_parts'].nil? && server_data['included_parts'].nil?
        errors << ['Server must have parts']
      end
      errors
    end

    def self.get_type(attrs)
      attrs.keys.grep(%r{/}).first.split('/').first
    end

    def self.strip_namespaces_from_keys(map)
      map.reduce({}) do |ac, (k, v)|
        ac.merge(k.split('/').last => v)
      end
    end

    def self.parts_list(parts)
      parts.map { |p| print_part(p) }
    end

    def self.print_part(attrs, column_width = 20)
      type = get_type(attrs)
      method_name = "print_part_#{type}"
      fail ArgumentError, "No renderer for #{type}" unless
         self.respond_to?(method_name)
      send(method_name, attrs, column_width)
    end

    def self.print_part_processor(attrs, column_width)
      line = "processor/#{attrs['id'].slice(0, 8)}".ljust(column_width)
      line += attrs['processor/model_number'].ljust(column_width)
      line + "#{attrs['processor/speed']} Ghz #{attrs['processor/wattage']} watts"
    end

    def self.print_part_memory(attrs, column_width)
      line = "memory/#{attrs['id'].slice(0, 8)}".ljust(column_width)
      line += attrs['memory/model_number'].ljust(column_width)
      line + "#{attrs['memory/type']} #{attrs['memory/capacity_gb']} gb"
    end

    def self.print_part_disk(attrs, column_width)
      line = "disk/#{attrs['id'].slice(0, 8)}".ljust(column_width)
      line += attrs['disk/model_number'].ljust(column_width)
      line += "#{attrs['disk/interface']} #{attrs['disk/capacity_gb']} gb"
      line + " #{attrs['disk/speed']} rpms"
    end

    def self.print_part_chassis(attrs, column_width)
      line = "chassis/#{attrs['id'].slice(0, 8)}".ljust(column_width)
      line + attrs['chassis/model_number'].ljust(column_width)
    end
  end
end
