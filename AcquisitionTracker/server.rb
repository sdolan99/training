require 'sinatra'

module AcquisitionTracker
  class AtServer < Sinatra::Base
    get '/' do
      "Hello world"
    end
  end
end