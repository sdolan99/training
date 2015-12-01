require 'time'
require 'minitest/autorun'
require_relative 'read_journal'

include AquisitionTracker::ReadJournal

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
    given = { 'facts' => [[':assert', ':_mike', 'person/name', 'Mike']] }
    expect = { 'facts' => [[':assert', 'afba69ea8fd784d2ed85080dd3adc127', 'person/name', 'Mike']] }
    actual = substitute_real_fact_uuids!(given)
    assert_equal expect, actual
  end
end
