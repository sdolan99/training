require 'minitest/autorun'
require_relative 'queries'

include AcquisitionTracker::Queries
describe 'it prints the entities' do
  it 'prints' do
    given = [
      [':assert', 'eid-1', 'processor/model', 'E3-21'],
      [':assert', 'eid1', 'processor/speed', 'fast'],
      [':assert', 'eid-2', 'processor/model', 'E4'],
      [':assert', 'eid-1-1', 'acquisition/timestamp', '1'],
    ]
    actual = inventory_status(given)
    expected = { 'nothing' => [] }
    assert_equal expected, actual
  end
end
