require 'time'
require 'yaml'
require 'digest/sha1'

# Application Namespace
module AquisitionTracker
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
      journal_entry['facts'].each do |fact|
        fact.map! do |e|
          if e.respond_to?(:each)
            e.map! do |v|
              v.to_s.match(/\A:_/) ?
                Digest::SHA1.hexdigest(v).slice(0, 32) : e
            end
          else
            e.to_s.match(/\A:_/) ? Digest::SHA1.hexdigest(e).slice(0, 32) : e
          end
        end
      end
      journal_entry
    end
    module_function :substitute_real_fact_uuids!
  end
end

if $PROGRAM_NAME == __FILE__
  include AquisitionTracker::ReadJournal
  # read yaml from stdin, transform, write yaml to stdout
  puts YAML.dump_stream(*transform_seed_entries(YAML.load_stream($stdin.read)))
end
