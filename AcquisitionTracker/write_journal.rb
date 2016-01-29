require 'yaml'

module AcquisitionTracker
  # Write journal to disk
  module JournalWriter
    def self.entry(entry, options = {})
      options[:devmode] = options.key?(:devmode) ? options[:devmode] : ENV['AT_DEV']
      entry = ReadJournal.substitute_real_fact_uuids!(entry)
      entry_yaml = YAML.dump(entry)
      unless options.key?(:file)
        options[:file] = options[:devmode] ? DEV_JOURNAL : PROD_JOURNAL
      end

      if options.key?(:writestream)
        options[:writestream].puts(entry_yaml)
      elsif options.key?(:file)
        File.open(options[:file], 'a+') do |file|
          file.puts(entry_yaml)
        end
      else
        fail ArgumentError, 'No location to write journal specified'
      end
    end
  end
end
