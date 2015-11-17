#!/usr/bin/env ruby
require 'time'

 maplist = {
  ':_mike': '45736D07-94F9-4DB8-BAC6-02DC455B3B73',
  ':_E3-1231': '5497558D-3A0C-459F-ACA7-381610C359A4',
  ':_poweredge13_ram': '56C5F8C6-7D73-4248-BA8A-AF7A36AABC9B',
  ':_dellSata6': '096FF699-FCF2-4D57-AFF8-90362C6E46FC',
  ':_poweredge13': '6E5DEB0B-91A1-45D8-902D-F5AE50DF2D28',
  ':_E3-1231_1': '600CA46E-6DE2-4DED-A25A-A92A31277811',
  ':_poweredge13_ram_1': '53F78857-1C98-4C85-8C09-12D8643D5E61',
  ':_dellSata6_1': 'A037B328-A4E8-483C-94F1-B43B4DD778E3',
  ':_poweredge13_1': '0CAD0653-AFCB-452E-8C9F-752DA8E1BC07',
  ':_server1': 'B42C6EA7-15FA-4931-9F24-720F89357D62',
  ':_deploy1': 'A7E44B53-2511-4944-8BA1-DB58E940CA89',
}

# input journal entries output the same
def substitute_real_timestamps( journal_entries, epoc )
  increment = 60
  journal_entries.each do |entry|
    entry['timestamp'] = epoc + entry['timestamp'].split('t')[1].to_i * increment
    # Can change this to just entry['keys'] if needed
    entry.keys do |fact|
      fact.map! { |e| e.match(/\A:_t\d+\z/) ? e.split('t')[1].to_i * increment : e }
    end
  end
end

def substitute_real_fact_uuids( journal_entries, uuid_map )
  journal_entries.each do |entry|
    entry['facts'].each do |fact|
      fact.map! { |e| e.match(/\A:_/) ? uuid_map[e] : e }
    end
  end
end


def check_timestamps
  given = [ {'timestamp' => ':_t1'}, ]
  expect = [ {'timestamp' => Time.parse('2015-11-13 00:01:00 -0800')} ]
  epoc = Time.parse('2015-11-13 00:00:00 -0800')
  actual = substitute_real_timestamps(given, epoc)
  puts "check_timestamps: #{expect == actual}"
  puts "#{expect} != #{actual}" if expect != actual
end

def check_uuid
  maplist = { ':_mike' => '45736D07-94F9-4DB8-BAC6-02DC455B3B73' }
  given = [{'facts'=>[[':assert', ':_mike', 'person/name', 'Mike']]}]
  expect = [{'facts'=>[[':assert', '45736D07-94F9-4DB8-BAC6-02DC455B3B73', 'person/name', 'Mike']]}]
  actual = substitute_real_fact_uuids(given, maplist)
  puts "check_uuid: #{expect == actual}"
  puts "#{expect} != #{actual}" if expect != actual
end

if ENV['test']
  check_timestamps
  check_uuid
end
