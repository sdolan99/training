# Application Namespace
module AquisitionTracker
  # Functions that filter the indexes
  module Queries
    def self.inventory_status indexes = Indexes
      # fetches, loops, branches etc
      # return data structure
    end

    def self.inventory_status_report io = $stdout, indexes = Indexes
      data = inventory_status
      # write formatted data to io object ...
      warn 'inventory_status_report not implemented'
    end
  end
end
