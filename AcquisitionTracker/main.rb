require_relative 'read_journal'
require_relative 'commands'
require_relative 'queries'
require_relative 'ui'

# Application Namespace
module AcquisitionTracker
  module Cli
    SEED_JOURNAL = 'seed.yaml'
    DATA_DIR = "#{ENV['HOME']}/.AcquisitionTracker"
    PROD_JOURNAL = File.join(DATA_DIR, 'journal.yaml')
    DEV_JOURNAL = File.join(DATA_DIR, 'dev_journal.yaml')
    # cli entry point
    def self.run(args) # rubocop:disable Metrics/MethodLength
      hydrate load_journal_entries
      # handle inventory_status report
      if args.first == 'low_inventory_report'
        data = Queries.low_inventory_report
        Ui.inventory_status_report(data)
        exit
      end
      if args.first == 'inventory_report'
        data = Queries.inventory_report
        Ui.inventory_status_report(data)
        exit
      end
      if args.first == 'add_server'
        data = Queries.all_parts
        Ui.add_server(data)
        exit
      end

      if args.first == 'add_part'
        data = Queries.all_parts
        Ui.add_part(data)
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
        '  add_part   - (not functional) Add New Part',
      ].join("\n")
    end

    def self.load_journal_entries(devmode = ENV.key?('AT_DEV')) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      ensure_access
      if devmode
        journal_text = File.read(SEED_JOURNAL)
        journal_entries = YAML.load_stream(journal_text)
        journal_entries = ReadJournal.transform_seed_entries(journal_entries)
        dev_entries = []
        if File.exist?(DEV_JOURNAL)
          dev_journal_text = File.read(DEV_JOURNAL)
          dev_entries = YAML.load_stream(dev_journal_text)
        end
        return journal_entries + dev_entries
      else
        unless File.exist?(PROD_JOURNAL)
          File.write(PROD_JOURNAL, '')
          return []
        end
        journal_text = File.read(PROD_JOURNAL)
        journal_entries = YAML.load_stream(journal_text)
        return journal_entries
      end
    end

    # Ensure journal is writable
    # Expected to crash if it cannot write a directory (no write privileges)
    def self.ensure_access(directory = DATA_DIR)
      Dir.mkdir(directory) unless File.directory?(directory)
      fail IOError, "#{directory} is not writable" unless File.writable?(directory)
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
end

# only invoke run if this module used as entry point from the shell
AcquisitionTracker::Cli.run(ARGV) if $PROGRAM_NAME == __FILE__
