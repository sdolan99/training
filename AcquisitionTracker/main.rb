require_relative 'read_journal'
require_relative 'commands'
require_relative 'queries'
require_relative 'ui'

# Application Namespace
module AcquisitionTracker
  SEED_PATH = 'seed.yaml'
  # cli entry point
  def self.run(args, journal_path = SEED_PATH)
    hydrate load_journal_entries journal_path
    # handle inventory_status report
    if args.first == 'inventory_status'
      data = Queries.inventory_status_report
      Ui.inventory_status_report(data)
      exit
    end
    if args.first == 'add_server'
      data = Queries.all_parts
      Ui.add_server(data)
      exit
    end
    # if we got here the cli args couldn't be passed, show help
    puts help_msg
  end

  def self.help_msg
    [
      'Available commands:',
      '  inventory_status - report what items need to buying',
      '  add_server - record acquisition of new server',
    ].join("\n")
  end

  def self.load_journal_entries(journal_path = SEED_PATH)
    journal_text = File.read(journal_path)
    journal_entries = YAML.load_stream(journal_text)
    # seeds (but only seeds) must be transformed before use
    if journal_path == SEED_PATH
      journal_entries = ReadJournal.transform_seed_entries(journal_entries)
    end
    journal_entries
  end

  # loads the journal into the indexes
  def self.hydrate(journal_entries)
    journal_entries.each do |journal_entry|
      command_name = journal_entry['command_name']
      facts = journal_entry['facts']
      Commands.send('index_' + command_name, facts)
    end
  end
end

# only invoke run if this module used as entry point from the shell
AcquisitionTracker.run(ARGV) if $PROGRAM_NAME == __FILE__
