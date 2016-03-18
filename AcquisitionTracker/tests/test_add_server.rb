require_relative '../server'
require 'minitest/autorun'
require 'rack/test'
require 'pp'

class AtTest < Minitest::Test
  include Rack::Test::Methods

  def app
    AcquisitionTracker::AtServer
  end

  def test_acquire_server
    before_acquisitions = AcquisitionTracker::Indexes[:acquisition_entities].size
    get '/acquire_server/'
    assert_equal(200, last_response.status)
    assert_equal({}, $session[:acquire_server])
    post '/acquire_server/included_parts/', { part_id: '4124' }
    assert_equal(['4124'], $session[:acquire_server][:included_parts])
    assert_equal('http://example.org/acquire_server/', last_response.header['Location'])
    post '/acquire_server/', { :date_acquired => '1-1-1' }
    after_acquisitions = AcquisitionTracker::Indexes[:acquisition_entities].size
    assert_equal(1, after_acquisitions - before_acquisitions)
  end

end
