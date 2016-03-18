require 'minitest/autorun'
require 'stringio'
require_relative 'translate'
require 'pp'

describe 'Ui::Translate.create_new_part_facts' do
  # Parameters:
  #   requires:
  #     - new_part - {
  #       'parttype/temp_id' => 'temporaryid'
  #       'parttype/propert1' => 'dragon',
  #       'parttype/property2' => 'cat'
  #       }
  #
  #     - date_acquired - '2016-03-18 14:08:43 -0700'
  #     - index - 1
  #     - ranndv - 42
  #   returns:
  #     [
  #       [":assert", ":_parttype_temporaryid_42", "parttype/property1", "dragon"],
  #       [":assert", ":_parttype_temporaryid_42", "parttype/property2", "cat"],
  #       [ ':assert', ':_acquisition_1_42', 'acquisition/timestamp', '2016-03-18 14:08:43 -0700' ]
  #       [ ':assert', ':_acquisition_1_42', 'acquisition/part_id', ':_parttype_temporaryid_42 ]
  #       [ ':assert', ':_acquisition_1_42', 'acquisition/acquirer, ':_mike ]
  #     ]
  #
  part_attrs = {
    'parttype/temp_id' => 'temporaryid',
    'parttype/property1' => 'dragon',
    'parttype/property2' => 'cat'
  }

  date_acquired = '2016-03-18 14:08:43 -0700'
  index = 1
  randv = 42

  expected = [
    [":assert", ":_parttype_temporaryid_42", "parttype/property1", "dragon"],
    [":assert", ":_parttype_temporaryid_42", "parttype/property2", "cat"],
    [ ':assert', ':_acquisition_1_42', 'acquisition/timestamp', '2016-03-18 14:08:43 -0700' ],
    [ ':assert', ':_acquisition_1_42', 'acquisition/part_id', ':_parttype_temporaryid_42' ],
    [ ':assert', ':_acquisition_1_42', 'acquisition/acquirer', ':_mike' ]
  ]
  result = AcquisitionTracker::Ui::Translate.create_part_and_acquisition_facts(part_attrs, date_acquired, index, randv)
  it 'produces correct list of facts' do
    assert_equal expected, result
  end
end
