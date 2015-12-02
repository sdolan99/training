# Application Namespace
module AquisitionTracker
  # In-memory, indexed representation of the application's data
  module Indexes
    # an index accessor that lazily creates maps
    def self.[](index_name)
      @indexes ||= Hash.new
      @indexes[index_name] ||= Hash.new
      @indexes[index_name]
    end
  end
end
