require 'time'
require 'minitest/autorun'
require_relative 'read_journal'

describe 'substitute_real_timestamps' do
  it 'Works for :t_1' do
    given = { 'timestamp' => ':_t1' }
    expect = { 'timestamp' => Time.parse('2015-11-13 00:01:00 -0800') }
    epoc = Time.parse('2015-11-13 00:00:00 -0800')
    actual = substitute_real_timestamps!(given, epoc)
    assert_equal expect, actual
  end
end

describe 'substtute_real_fact_uuids' do
  it 'Works for :_mike' do
    maplist = { ':_mike' => '45736D07-94F9-4DB8-BAC6-02DC455B3B73' }
    given = { 'facts' => [[':assert', ':_mike', 'person/name', 'Mike']] }
    expect = { 'facts' => [[':assert', '45736D07-94F9-4DB8-BAC6-02DC455B3B73', 'person/name', 'Mike']] }
    actual = substitute_real_fact_uuids!(given, maplist)
    assert_equal expect, actual
  end
end

# def check_timestamps
#   given = [ {'timestamp' => ':_t1'}, ]
#   expect = [ {'timestamp' => Time.parse('2015-11-13 00:01:00 -0800')} ]
#   epoc = Time.parse('2015-11-13 00:00:00 -0800')
#   actual = substitute_real_timestamps(given, epoc)
#   puts "check_timestamps: #{expect == actual}"
#   puts "#{expect} != #{actual}" if expect != actual
# end

# def check_uuid
#   maplist = { ':_mike' => '45736D07-94F9-4DB8-BAC6-02DC455B3B73' }
#   given = [{'facts'=>[[':assert', ':_mike', 'person/name', 'Mike']]}]
#   expect = [{'facts'=>[[':assert', '45736D07-94F9-4DB8-BAC6-02DC455B3B73', 'person/name', 'Mike']]}]
#   actual = substitute_real_fact_uuids(given, maplist)
#   puts "check_uuid: #{expect == actual}"
#   puts "#{expect} != #{actual}" if expect != actual
# end

# if ENV['test']
#   check_timestamps
#   check_uuid
# end
