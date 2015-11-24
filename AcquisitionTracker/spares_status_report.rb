require 'set'
require_relative 'read_journal'

# Reporting module.
#  - Checks and reports on inventory
module Reporting
  # Every journal entry contains 1 or more facts
  class Fact
    attr_reader :command, :uuid, :type, :value

    def initialize(command, uuid, type, value)
      @command = command
      @uuid = uuid
      @type = type
      @value = value
    end
  end

  MIN_SPARES = 2
  SPARE_TYPES = %w('processor', 'memory', 'ram', 'disk')

  def self.print_report(inventory)
    puts 'Inventory report:'
    inventory.each do |part, count|
      puts "Part #{part} - Have #{count} need #{MIN_SPARES - count} more" if count < MIN_SPARES
    end
  end

  def self.inventory(journal_entries)
    parts = {}
    journal_entries.each do |entry|
      entry['facts'].each do |fact|
        f = Fact.new(fact[0], fact[1], fact[2], fact[3])
        next unless f.type.include?('part_id')
        parts[f.value] = parts.key?(f.value) ? parts[f.value] + 1 : 1
      end
    end
    parts
  end

  def self.load_journal(stream)
    mje = YAML.load_stream(stream).map do |entry|
      substitute_real_timestamps!(entry)
      substitute_real_fact_uuids!(entry)
    end
    mje
  end

  def self.run(stream)
    mapped_journal_entries = Reporting.load_journal(stream)
    inventory = Reporting.inventory(mapped_journal_entries)
    Reporting.print_report(inventory)
  end
end

Reporting.run($stdin.read)
