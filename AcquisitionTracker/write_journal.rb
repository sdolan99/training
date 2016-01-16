module AcquisitionTracker
  # Write journal to disk
  module WriteJournal
    JOURNAL_PATH = 'journal.yaml'
    def self.user_entry(user_entry)
      File.write(JOURNAL_PATH, "---\n" + user_entry.to_yaml, 'a')
    end
  end
end
