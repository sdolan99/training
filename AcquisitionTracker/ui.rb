module AcquisitionTracker
  # UI functions for printing data
  module Ui
    def self.inventory_status_report(data)
      min_quantity = data['min_quantity']
      puts "Inventory Status Report"
      puts " Min quantity: #{min_quantity}"
      puts ""
      puts "Quantity  Type"

      data.each do |i, p|
        next if i == 'min_quantity'
        type = get_type(p['properties'])
        puts "#{p['count']} / #{min_quantity}   -  #{type}"
      end
    end

    def self.get_type(property)
      property.keys.grep(/\//).first.split('/').first
    end

    # In progress
    def self.get_properties(property)
      map = property.keys.grep(/\//).map{ |v| join(v.split('/').last, property[v], ' => ') }
      require 'pp'
      pp map
    end
  end
end
