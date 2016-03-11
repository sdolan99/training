require 'sinatra'
require_relative 'main'
require 'pry'

AcquisitionTracker::Commands.hydrate AcquisitionTracker::Journal.load_journal_entries


module AcquisitionTracker
  # TODO: Where do we hydrate on startup?
  class AtServer < Sinatra::Base
    $session = {}

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
      parts_list = Queries.all_parts
      erb :add_existing_part_form, :locals => {:parts_list => parts_list}
    end

    post '/acquire_part/' do
      user_entry = {}
      user_entry['existing_part_id'] = params[:existing_part_id]
      user_entry['date_acquired'] = params[:date_acquired]
      add_part_entry = Ui::Translate.write_new_add_part_entry(user_entry, Queries.all_parts)
      puts add_part_entry
      Journal.write_entry(add_part_entry)
      Commands.hydrate([add_part_entry])
      redirect '/'
    end

    get '/acquire_new_part/' do
      erb :add_new_part_form, :locals => { :selected_part_type => params[:selected_part_type] }
    end

    post '/acquire_new_part/' do
      "Parts are: #{params}"
    end

    get '/acquire_server/' do
      $session[:acquire_server] ||= {}
      "acquire server"
    end

    post '/acquire_server/' do
      # Submit to database
      $session[:acquire_server][:date_acquired] = params[:date_acquired]
      id = Ui::Web.acquire_server($session[:acquire_server])
      $session[:acquire_server] = nil
      $session[:last_acquire_server_id] = id
      redirect '/' unless id
    end

    post '/acquire_server/included_parts/' do
      $session[:acquire_server][:included_parts] ||= []
      $session[:acquire_server][:included_parts] << params[:part_id]
      redirect '/acquire_server/'
    end

    get '/add_names/' do
      $session[:names] ||= []
      erb :names, :locals => { :names => $session[:names] }
    end

    post '/add_names/insert_name/' do
      $session[:names] << params[:name]
      redirect '/add_names/'
    end

    post '/add_names/delete_name/' do
      $session[:names].delete(params[:name])
      redirect '/add_names/'
    end
  end
end
