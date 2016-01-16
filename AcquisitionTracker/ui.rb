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
#{parts_list_string.map { |l| " # - #{l.strip}"}.join("\n")}

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
      user_entry, errors = read_user_entry(tmp_path)
      until errors.empty?
        puts errors
        puts "Press enter to continue correcting errors."
        $stdin.gets
        user_entry, errors = read_user_entry(tmp_path)
      end
      puts "No errors detected"
      # TODO: Create a journal entry from user entry
      # TODO: Translate to acquire_server journal entry
      # Need current user, timestamp and the group/unit
      # journal_entry = create_journal_entry_from_user_entry(user_entry)
      # WriteJournal.user_entry(journal_entry)
    end

    def self.read_user_entry(tmp_path)
      editor = ENV['EDITOR'] || 'vi'
      open_editor_command = "#{editor} #{tmp_path}"
      system(open_editor_command)
      user_entry_yaml = File.read(tmp_path)
      user_entry = YAML.load(user_entry_yaml)
      errors = validate_add_server_data(user_entry)
      return [user_entry, errors]
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
        ac.merge( k.split('/').last => v )
      end
    end

    def self.parts_list(parts)
      parts.map { |p| print_part(p) }
    end

    def self.print_part(attrs, column_width = 20)
      type = get_type(attrs)
      method_name = "print_part_#{type}"
      raise ArgumentError.new("No renderer for #{type}") unless
         self.respond_to?(method_name)
      self.send(method_name, attrs, column_width)
    end

    def self.print_part_processor(attrs, column_width)
      line = "processor/#{attrs['id'].slice(0,8)}".ljust(column_width)
      line += attrs['processor/model_number'].ljust(column_width)
      line += "#{attrs['processor/speed']} Ghz #{attrs['processor/wattage']} watts"
    end

    def self.print_part_memory(attrs, column_width)
      line = "memory/#{attrs['id'].slice(0,8)}".ljust(column_width)
      line += attrs['memory/model_number'].ljust(column_width)
      line += "#{attrs['memory/type']} #{attrs['memory/capacity_gb']} gb"
    end

    def self.print_part_disk(attrs, column_width)
      line = "disk/#{attrs['id'].slice(0,8)}".ljust(column_width)
      line += attrs['disk/model_number'].ljust(column_width)
      line += "#{attrs['disk/interface']} #{attrs['disk/capacity_gb']} gb"
      line += " #{attrs['disk/speed']} rpms"
    end

    def self.print_part_chassis(attrs, column_width)
      line = "chassis/#{attrs['id'].slice(0,8)}".ljust(column_width)
      line += attrs['chassis/model_number'].ljust(column_width)
    end
  end
end
