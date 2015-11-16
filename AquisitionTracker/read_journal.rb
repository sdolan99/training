#!/usr/bin/env ruby
require 'time'

# input journal entries output the same
def substitute_real_timestamps( journal_entries, epoc )
  journal_entries
end


def check_timestamps
  given = [ {'timestamp' => :_t1}, ]
  expect = [ {'timestamp' => Time.parse('2015-11-13 00:01:00 -0800')} ]
  epoc = Time.parse('2015-11-13 00:00:00 -0800')
  actual = substitute_real_timestamps(given, epoc)
  puts "#{expect} == #{actual} : #{expect == actual}"
end

def check_uuid
end
if ENV['test']
  check_timestamps
end
