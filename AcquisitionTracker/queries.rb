# Application Namespace
module AcquisitionTracker
  # Functions that filter the indexes
  module Queries
    def self.inventory_status(indexes = Indexes)
      parts = TwoLevelHash.new
      # find all the purchased parts
      indexes['acquisition_entities'].each do |_, properties|
        # Can this function be a map?
        parts[properties['acquisition/part_id']]['count'] ||= 0
        parts[properties['acquisition/part_id']]['count'] += 1
        parts[properties['acquisition/part_id']]['properties'] =
          indexes['entities'][properties['acquisition/part_id']]
      end
      parts
    end

    MIN_QUANTITY = 3
    def self.inventory_status_report(_io = $stdout, indexes = Indexes)
      data = inventory_status(indexes)
      order = data.select { |_, v| v['count'] < MIN_QUANTITY }
      order['min_quantity'] = MIN_QUANTITY
      order
    end
  end
end
