
# Application Namespace
module AcquisitionTracker
  # In-memory, indexed representation of the application's data
  class TwoLevelHash
    extend Forwardable
    def initialize
      @toplevel = {}
    end

    def [](index_name)
      @toplevel[index_name] ||= {}
      @toplevel[index_name]
    end

    def_delegator :@toplevel, :keys
    def_delegator :@toplevel, :each
    def_delegator :@toplevel, :select
  end
  Indexes = TwoLevelHash.new
end

if $PROGRAM_NAME == __FILE__
  AcquisitionTracker::Indexes['a']['b'] = 'c'
  puts AcquisitionTracker::Indexes['a']['b']
end
