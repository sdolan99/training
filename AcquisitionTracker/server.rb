require 'sinatra'
require_relative 'main'
require 'pry'

AcquisitionTracker::Commands.hydrate AcquisitionTracker::Journal.load_journal_entries


module AcquisitionTracker
  # TODO: Where do we hydrate on startup?
  class AtServer < Sinatra::Base
    get '/' do
      erb :index
    end

    get '/api' do
      erb :api
    end

    get '/inventory_report/' do
      data = Queries.inventory_report
      min_quantity = data.key?('min_quantity') ? data['min_quantity'] : 0
      erb :ir, :locals => { 'data' => data, 'min_quantity' => min_quantity }
    end

    get '/acquire_part/' do
      parts_list = Ui::parts_list(Queries.all_parts).map { |l| l.strip }
      puts "parts are:"
      puts parts_list
      erb :add_part_form, :locals => {:parts_list => parts_list}
    end

    post '/acquire_part/' do
      user_entry = {}
      user_entry['existing_part_id'] = params[:existing_part_id]
      user_entry['date_acquired'] = params[:date_acquired]
      add_part_entry = Ui::Translate.write_new_add_part_entry(user_entry, Queries.all_parts)
      puts add_part_entry
      Journal.write_entry(add_part_entry)
      Commands.hydrate([add_part_entry])
      "Added part #{user_entry['existing_part_id']}"
    end
  end
end
