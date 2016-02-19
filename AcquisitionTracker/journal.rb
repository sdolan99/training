module AcquisitionTracker
  # Manage the journal entries
  module  Journal
    SEED_JOURNAL = 'seed.yaml'
    DATA_DIR = "#{ENV['HOME']}/.AcquisitionTracker"
    PROD_JOURNAL = File.join(DATA_DIR, 'journal.yaml')
    DEV_JOURNAL = File.join(DATA_DIR, 'dev_journal.yaml')

    def self.load_journal_entries(devmode = ENV.key?('AT_DEV')) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      ensure_access
      if devmode
        journal_text = File.read(SEED_JOURNAL)
        journal_entries = YAML.load_stream(journal_text)
        journal_entries = TransformJournal.transform_entries(journal_entries)
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

    # Write journal to disk

    def self.write_entry(entry, options = {})
      options[:devmode] = options.key?(:devmode) ? options[:devmode] : ENV['AT_DEV']
      entry = TransformJournal.substitute_real_fact_uuids!(entry)
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
