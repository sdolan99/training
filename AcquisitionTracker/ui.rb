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
        puts "#{p['count']} / #{min_quantity}   -  #{p['properties']}"
      end
    end
  end
end
