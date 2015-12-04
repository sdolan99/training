# Application Namespace
module AquisitionTracker
  # Functions that filter the indexes
  module Queries
    def self.inventory_status(_indexes = Indexes)
      # fetches, loops, branches etc
      # return data structure
    end

    def self.inventory_status_report(_io = $stdout, _indexes = Indexes)
      _data = inventory_status
      # write formatted data to io object ...
      warn 'inventory_status_report not implemented'
    end
  end
end
