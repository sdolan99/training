module AcquisitionTracker
  # UI functions for printing data
  module Ui
    def self.inventory_status_report(data)
      require 'pp'
      pp data
    end
  end
end
