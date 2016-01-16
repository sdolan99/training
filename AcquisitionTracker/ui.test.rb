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

  it 'gets property names wo namespace' do
    given = {
      'id' => 'ac542f76ba25a578c5a86c5c922a3b84',
      'disk/capacity_gb' => 500,
      'disk/interface' => 'sata',
      'disk/speed' => '7.2' }
    expect = {
      'id' => 'ac542f76ba25a578c5a86c5c922a3b84',
      'capacity_gb' => 500,
      'interface' => 'sata',
      'speed' => '7.2' }
    actual = AcquisitionTracker::Ui.strip_namespaces_from_keys(given)
    assert_equal expect, actual
  end

  it 'gets parts list to be used in yaml to user' do
    expect = [
      "processor/464697fa  E3-1231             3.4 Ghz 80 watts",
      "memory/12345678     dell_ram            rdimm 16 gb"
    ]

    given = [
             { 'id' => '464697fabcd',
               'processor/model_number' => 'E3-1231',
               'processor/speed' => 3.4,
               'processor/wattage' => 80,
               'disk/speed' => '7.2' },
             { 'id' => '12345678920',
               'memory/model_number' => 'dell_ram',
               'memory/type' => 'rdimm',
               'memory/capacity_gb' => 16 },
    ]

    actual = AcquisitionTracker::Ui.parts_list(given)
    assert_equal expect, actual
  end

  it 'prints processor part lines' do
    given = {
     "id"=>"3464697f202a3f426bded86951a4d4e1",
     "processor/model_number"=>"E3-1231",
     "processor/speed"=>"3.4",
     "processor/wattage"=>80}

   expect = "processor/3464697f  E3-1231             3.4 Ghz 80 watts"
   actual = AcquisitionTracker::Ui.print_part(given)
   assert_equal expect, actual
  end

end
