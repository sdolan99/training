require 'time'
require 'yaml'
require 'digest/sha1'

# Application Namespace
module AcquisitionTracker
  # Functions to transform seed journal entries into "real" ones
  module ReadJournal
    # journal_entries -> journal_entries
    def transform_seed_entries(journal_entries)
      journal_entries.map do |journal_entry|
        substitute_real_timestamps!(journal_entry)
        substitute_real_fact_uuids!(journal_entry)
      end
    end
    module_function :transform_seed_entries

    # symbol, time, int -> time
    def transform_timestamp(timecode, starting_time, increment)
      return timecode unless timecode.to_s.match(/\A:_t\d+\z/)
      starting_time + timecode.split('t')[1].to_i * increment
    end
    module_function :transform_timestamp

    # journal_entry -> journal_entry
    def substitute_real_timestamps!(journal_entry, epoc = Time.now, increment = 60)
      journal_entry['timestamp'] = transform_timestamp(journal_entry['timestamp'], epoc, increment)

      journal_entry['facts'].each do |fact|
        fact.map! { |e| transform_timestamp(e, epoc, increment) }
      end
      journal_entry
    end
    module_function :substitute_real_timestamps!

    # journal_entry -> journal_entry
    def substitute_real_fact_uuids!(journal_entry)
      journal_entry['facts'].map! do |fact|
        substitute_uuid!(fact)
      end
      journal_entry
    end
    module_function :substitute_real_fact_uuids!

    # TODO: not working in reverts.  Support translation
    def substitute_uuid!(value_node)
      if value_node.respond_to?(:each)
        value_node.map! do |v|
          substitute_uuid!(v)
        end
      else
        if value_node.to_s.match(/\A:_/)
          Digest::SHA1.hexdigest(value_node).slice(0, 32)
        else
          value_node
        end
      end
    end
    module_function :substitute_uuid!
  end # /ReadJournal
end

if $PROGRAM_NAME == __FILE__
  include AcquisitionTracker::ReadJournal
  # read yaml from stdin, transform, write yaml to stdout
  puts YAML.dump_stream(*transform_seed_entries(YAML.load_stream($stdin.read)))
end
