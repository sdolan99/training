require_relative './transform_journal'
require_relative './queries'
require_relative './journal'
require_relative './translate'

module AcquisitionTracker
  # UI functions for printing data
  module Ui
    def self.inventory_status_report(data = Queries.inventory_report, outstream = $stdout)
      min_quantity = data.key?('min_quantity') ? data['min_quantity'] : 0
      outstream.puts 'Inventory Status Report'
      if min_quantity != 0
        outstream.puts " Min quantity: #{min_quantity}"
        outstream.puts ''
      end
      outstream.puts 'Quantity  Type'

      data.each do |i, p|
        next if i == 'min_quantity'
        type = Translate.get_type(p['properties'])
        if min_quantity != 0
          outstream.puts "#{p['count']} / #{min_quantity}   -  #{type}"
        else
          outstream.puts "#{p['count']}  -  #{type}"
        end
      end
    end

    def self.add_server(parts_list = Queries.all_parts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # Generate yaml in temp file to open in users text edit
      # Returns, read context of file and parse/perform command
      context = { :parts_list_string => parts_list(parts_list) }
      file_contents = evaluate_template(AddServerTemplate, context )
      tmp_path = make_tmpfile_for_editing('ac-addserver.yaml', file_contents)
      user_entry = read_entry_until_valid { Translate.read_user_entry(tmp_path) }

      add_server_entry = Translate.create_journal_entry(user_entry, parts_list, 'acquire_server')
      Journal.write_entry(add_server_entry)
      Commands.hydrate([add_server_entry])
    end

    def self.add_part(parts_list = Queries.all_parts)
      # Generate yaml in temp file to open in users text edit
      # Returns, read context of file and parse/perform command
      context = { :parts_list_string => parts_list(parts_list) }
      file_contents = evaluate_template(AddPartTemplate, context)
      tmp_path = make_tmpfile_for_editing('ac-addpart.yaml', file_contents)
      user_entry = read_entry_until_valid { Translate.read_user_add_part_entry(tmp_path) }
      add_part_entry = Translate.create_journal_entry(user_entry, parts_list, 'acquire_part')

      Journal.write_entry(add_part_entry)
      Commands.hydrate([add_part_entry])
    end

    def self.parts_list(parts)
      parts.map { |p| print_part(p) }
    end

    def self.print_part(attrs, column_width = 20)
      type = Translate.get_type(attrs)
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

    def self.evaluate_template(template, context = {})
      b = binding
      v = nil

      context.each do |k, value|
        v = value
        eval("#{k.to_s} = v", b)
      end
      eval("\"" + template + "\"", b)
    end

    def self.make_tmpfile_for_editing(tmp_filename, contents)
      tmp_dir = ENV['TMPDIR'] || '/tmp'
      tmp_path = File.join(tmp_dir, tmp_filename)
      File.write(tmp_path, contents)
      tmp_path
    end

    def self.read_entry_until_valid(&blk)
      errors, user_entry = blk.call
      user_entry.nil?
      until errors.empty?
        puts errors
        puts 'Press enter to continue correcting errors.'
        $stdin.gets
        user_entry, errors = blk.call
      end
      puts 'No errors detected'
      user_entry
    end

    module Web
      def self.transform_hash(original, options={}, &block)
        original.inject({}){|result, (key,value)|
        value = if (options[:deep] && Hash === value)
                  transform_hash(value, options, &block)
                else
                    value
                end
        block.call(result,key,value)
        result
        }
      end

      # Convert keys to strings
      def self.stringify_keys(hash)
        transform_hash(hash) {|hash, key, value|
          hash[key.to_s] = value
        }
      end

      # Convert keys to strings, recursively
      def self.deep_stringify_keys(hash)
        transform_hash(hash, :deep => true) {|hash, key, value|
          hash[key.to_s] = value
        }
      end

      def self.acquire_server(params)
        params = stringify_keys(params)
        facts = params['included_parts'].flat_map { |pid| Translate.create_acquisition_facts_from_part_id(params, pid) }
        part_ids = facts
                        .select { |fact| fact[2] == 'acquisition/part_id' }
                        .map { |fact| fact[3] }
                        .uniq
        uuid = Digest::SHA1.hexdigest(rand.to_s).slice(0,32)
        group_fact = [
          ':assert',
          uuid,
          'group/units',
          part_ids,
        ]

        facts << group_fact
        add_server_entry_raw = {
           'timestamp' => Time.now,
           'command_name' => 'acquire_server',
           'facts' => facts,
        }
        add_server_entry = TransformJournal.transform_entries([add_server_entry_raw]).first
        Journal.write_entry(add_server_entry)
        Commands.hydrate([add_server_entry])
        uuid
      end
    end # End Web
  end # End UI
end # End AcquisitionTracker

AcquisitionTracker::Ui::AddServerTemplate = <<'EOY'
# add server
# -- Parts list
#{parts_list_string.map { |l| "# - #{l.strip}" }.join("\n")}

# Does the Server need any parts not in the above list?
new_parts:
#- processor/temp_id: 1
#  processor/model_number: Model-21A
#  processor/speed: 10
#  processor/wattage: 80
#- memory/temp_id: 2
#  memory/model_number: hpram13-25
#  memory/type: dram
#  memory/capacity_gb: 34

# What Parts is the Server made from?
included_parts:
#- processor/xxxxxx
#- memory/xxxxxxx
# ...

# What date was it acquired?
date_acquired: #{Time.now.to_s.split(' ').first}
EOY

AcquisitionTracker::Ui::AddPartTemplate = <<'EOY'
# add part

# either select id of existing part

#{parts_list_string.map { |l| "#  #{l.strip}" }.join("\n")}

existing_part_id:


# or, introduce a new part and record its aquisition:

# part attrs:
#
# processor/temp_id (int)
# processor/model_number (str)
# processor/speed
# processor/wattage
#
# memory/temp_id
# memory/model_number
# memory/type: dram
# memory/capacity_gb

# e.g. ucomment these lines to add a processor
#new_part:
#  processor/model_number: ...
#  processor/speed: ...
#  processor/wattage: ...

# What date was it acquired?
date_acquired: #{Time.now.to_s.split(' ').first}
EOY
