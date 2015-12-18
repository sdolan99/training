module AcquisitionTracker
  # UI functions for printing data
  module Ui
    def self.inventory_status_report(data, outstream = $stdout)
      min_quantity = data['min_quantity']
      outstream.puts 'Inventory Status Report'
      outstream.puts " Min quantity: #{min_quantity}"
      outstream.puts ''
      outstream.puts 'Quantity  Type'

      data.each do |i, p|
        next if i == 'min_quantity'
        type = get_type(p['properties'])
        outstream.puts "#{p['count']} / #{min_quantity}   -  #{type}"
      end
    end

    def self.get_type(property)
      property.keys.grep(%r{/}).first.split('/').first
    end

    # In progress
    def self.get_properties(property)
      map = property.keys.grep(%r{/}).map { |v| join(v.split('/').last, property[v], ' => ') }
      require 'pp'
      pp map
    end
  end
end
