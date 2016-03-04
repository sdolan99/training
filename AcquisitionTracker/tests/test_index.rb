require_relative './server'
require 'test/unit'
require 'rack/test'

class AtTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get '/'
  end

  def test_acquire_part_form_post
    post '/acquire_part/', params={:existing_part_id => '123', :date_acquired => '222'
  end
end
