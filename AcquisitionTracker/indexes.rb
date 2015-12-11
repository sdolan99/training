# Application Namespace
module AquisitionTracker
  # In-memory, indexed representation of the application's data
  class TwoLevelHash
    def initialize
      @toplevel = {}
    end

    def [](index_name)
      @toplevel[index_name] ||= {}
      @toplevel[index_name]
    end
  end
  Indexes = TwoLevelHash.new
end

if $PROGRAM_NAME == __FILE__
  AquisitionTracker::Indexes['a']['b'] = 'c'
  puts AquisitionTracker::Indexes['a']['b']
end
