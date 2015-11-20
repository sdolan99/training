require 'time'
require 'yaml'

# input journal entry output the same
# mutates journal_entries
def substitute_real_timestamps!(journal_entry, epoc = Time.now, increment = 60)
  journal_entry['timestamp'] = epoc + journal_entry['timestamp'].split('t')[1].to_i * increment
  # Can change this to just entry['facts'] if needed
  journal_entry.keys do |fact|
    fact.map! { |e| e.match(/\A:_t\d+\z/) ? e.split('t')[1].to_i * increment : e }
  end
  journal_entry
end

def substitute_real_fact_uuids!(journal_entry, uuid_map)
  journal_entry['facts'].each do |fact|
    fact.map! { |e| e.match(/\A:_/) ? uuid_map[e] : e }
  end
  journal_entry
end

if $0 == 'ruby'
  mapped_journal_entries = YAML.load_stream($stdin.read).map do |journal_entry|
    substitute_real_timestamps!(journal_entry)
    substitute_real_fact_uuids!(journal_entry)
  end

  puts YAML.dump_stream(mapped_journal_entries)
end
