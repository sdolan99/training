require 'sinatra'
require_relative 'main'

module AcquisitionTracker
  # TODO: Where do we hydrate on startup?
  class AtServer < Sinatra::Base
    get '/' do
      erb:index
    end

    get '/api' do
      erb:api
    end

    get '/api/v1/inventory-report' do
      Commands.hydrate Journal.load_journal_entries
      data = Queries.inventory_report
      returnstring = StringIO.new
      Ui.inventory_status_report(data, returnstring)
      returnstring.string
    end

  end
end
