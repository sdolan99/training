require 'time'
require 'yaml'
require 'digest/sha1'

def transform_timestamp(timecode, starting_time, increment)
  return timecode unless timecode.to_s.match(/\A:_t\d+\z/)
  starting_time + timecode.split('t')[1].to_i * increment
end

# input journal entry output the same
# mutates journal_entries
def substitute_real_timestamps!(journal_entry, epoc = Time.now, increment = 60)
  journal_entry['timestamp'] = transform_timestamp(journal_entry['timestamp'], epoc, increment)

  # Can change this to just entry['facts'] if needed
  journal_entry.keys do |fact|
    fact.map! { |e| transform_timestamp(e, epoc, increment) }
  end
  journal_entry
end

def substitute_real_fact_uuids!(journal_entry)
  journal_entry['facts'].each do |fact|
    fact.map! { |e| e.to_s.match(/\A:_/) ? Digest::SHA1.hexdigest(e).slice(0,32) : e }
  end
  journal_entry
end

if $PROGRAM_NAME == __FILE__
  mapped_journal_entries = YAML.load_stream($stdin.read).map do |journal_entry|
    substitute_real_timestamps!(journal_entry)
    substitute_real_fact_uuids!(journal_entry)
  end

  puts YAML.dump_stream(*mapped_journal_entries)
end
