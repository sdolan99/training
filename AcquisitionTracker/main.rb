require_relative 'transform_journal'
require_relative 'commands'
require_relative 'queries'
require_relative 'ui'

# Application Namespace
module AcquisitionTracker
  module Cli
      # cli write_entry point
    def self.run(args) # rubocop:disable Metrics/MethodLength
      Commands.hydrate Journal.load_journal_entries
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
        '  inventory_report  - report all items',
        '  low_inventory_report - report what items need to buy',
        '  add_server - record acquisition of new server',
        '  add_part   - Add New Part',
      ].join("\n")
    end

   end
end

# only invoke run if this module used as write_entry point from the shell
AcquisitionTracker::Cli.run(ARGV) if $PROGRAM_NAME == __FILE__
