require 'minitest/autorun'
require 'stringio'
require_relative 'ui'

describe 'UI' do
  it 'Gives inventory status report' do
    expected = <<EOS
Inventory Status Report
 Min quantity: 3

Quantity  Type
1 / 3   -  processor
2 / 3   -  memory
1 / 3   -  disk
1 / 3   -  chassis
EOS

    given = { '3464697f202a3f426bded86951a4d4e1' =>
             { 'count' => 1,
               'properties' =>
             { 'id' => '3464697f202a3f426bded86951a4d4e1',
               'processor/model_number' => 'E3-1231',
               'processor/speed' => '3.4',
               'processor/wattage' => 80 } },
              'fbce36e02c03526bc9c7629cceba70b5' =>
             { 'count' => 2,
               'properties' =>
             { 'id' => 'fbce36e02c03526bc9c7629cceba70b5',
               'memory/type' => 'rdimm',
               'memory/capacity_gb' => 16,
               'memory/model_number' => 'poweredge13-16' } },
              'ac542f76ba25a578c5a86c5c922a3b84' =>
             { 'count' => 1,
               'properties' =>
             { 'id' => 'ac542f76ba25a578c5a86c5c922a3b84',
               'disk/capacity_gb' => 500,
               'disk/interface' => 'sata',
               'disk/speed' => '7.2' } },
              '74235f7710971ea109f85183ee72952d' =>
             { 'count' => 1,
               'properties' =>
             { 'id' => '74235f7710971ea109f85183ee72952d', 'chassis/model' => 'R720' } },
              'min_quantity' => 3 }

    writestream = StringIO.new
    AcquisitionTracker::Ui.inventory_status_report(given, writestream)
    assert_equal expected, writestream.string
  end
end
