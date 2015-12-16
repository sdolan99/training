require 'minitest/autorun'
require_relative 'commands'
require_relative 'indexes'

include AcquisitionTracker

describe 'Can acquire a server' do
  it 'Adds elements to the index' do
    given = [
      [':assert', 'eid-1', 'processor/model', 'E3-21'],
      [':assert', 'eid-1', 'processor/speed', 'fast'],
      [':assert', 'eid-2', 'processor/model', 'E4'],
      [':assert', 'eid-1-1', 'acquisition/timestamp', '1'],
    ]
    given_index = TwoLevelHash.new

    Commands.index_acquire_server(given, given_index)
    e_1 = { 'id' => 'eid-1',
            'processor/model' => 'E3-21',
            'processor/speed' => 'fast' }
    e_2 = { 'id' => 'eid-2',
            'processor/model' => 'E4' }
    ae_1 = { 'id' => 'eid-1-1',
             'acquisition/timestamp' => '1' }

    assert_equal e_1, given_index['entities']['eid-1']
    assert_equal e_2, given_index['entities']['eid-2']
    assert_equal e_1, given_index['part_entities']['eid-1']
    assert_equal ae_1, given_index['acquisition_entities']['eid-1-1']
  end
end
