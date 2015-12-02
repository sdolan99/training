require_relative 'read_journal'
require_relative 'commands'
require_relative 'queries'

# Application Namespace
module AquisitionTracker
  SEED_PATH = 'seed.yaml'
  # cli entry point
  def self.run args, journal_path = SEED_PATH
    journal_text = File.read(journal_path)
    journal_entries = YAML.load_stream(journal_text)
    # seeds (but only seeds) must be transformed before use
    if journal_path == SEED_PATH
      journal_entries = ReadJournal.transform_seed_entries(journal_entries)
    end
    hydrate journal_entries

    # handle the dump_journal command
    if args.first == 'dump_journal'
      puts YAML.dump_stream(*journal_entries)
      exit
    end

    if args.first == 'inventory_status'
      Queries.inventory_status_report
    end

    # if we got here the cli args couldn't be passed, show help
    puts [
      "Available commands:",
      "  inventory_status - report what items need to buying",
      "  dump_journal - load and print the contents of the journal (for debugging)",
    ].join("\n")
  end

  # loads the journal into the indexes
  def self.hydrate journal_entries
    journal_entries.each do |journal_entry|
      command_name = journal_entry['command_name']
      facts = journal_entry['facts']
      Commands.send('index_' + command_name, facts.map {|t| Fact.new(*t) })
    end
  end

  # fact record structure
  Fact = Struct.new :operation, :id, :attribute_name, :value
end

# only invoke run if this module used as entry point from the shell
if $PROGRAM_NAME == __FILE__
  AquisitionTracker.run(ARGV)
end

