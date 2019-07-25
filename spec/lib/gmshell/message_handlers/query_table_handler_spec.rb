require 'spec_helper'
require 'gmshell/message_handlers/query_table_handler'
require 'gmshell/table_registry'
require 'gmshell/table_entry'

module Gmshell
  module MessageHandlers
    RSpec.describe QueryTableHandler do
      let(:table_name) { 'programming' }
      describe '#call' do
        context "with a missing table_name" do
          let(:registry) do
            Gmshell::TableRegistry.new.tap do |registry|
              registry.register_by_string(table_name: "other", string: "1|Other")
            end
          end
          it "will return a message saying its missing and provide a list of matches" do
            expect(described_class.call(registry: registry, table_name: "o")).to eq(
              ['Unknown table "o". Did you mean: "other"']
            )
          end
        end
        [
          [
            ["1|Hello {bork}", "2|World"],
            { index: "1", expand: false },
            [Gmshell::TableEntry.new(line: "1|Hello {bork}")]
          ],[
            ["1|Hello {bork}", "2|World"],
            { grep: "world", expand: false },
            [Gmshell::TableEntry.new(line: "2|World")]
          ],[
            ["1|Hello {bork}", "2|World"],
            { grep: "{bork}", expand: false },
            [Gmshell::TableEntry.new(line: "1|Hello {bork}")]
          ],[
            ["1|Hello {bork}", "2|World"],
            { grep: "{bork}", expand: true },
            [Gmshell::TableEntry.new(line: "1|Hello {bork}")]
          ],[
            ["1|Hello {bork}", "2|World"],
            { grep: "o", expand: true },
            [Gmshell::TableEntry.new(line: "1|Hello {bork}"), Gmshell::TableEntry.new(line: "2|World")]
          ]
        ].each_with_index do |(table, given, expected), index|
          context "with #{given.inspect} for table: #{table.inspect} (scenario ##{index})" do
            let(:registry) do
              Gmshell::TableRegistry.new.tap do |registry|
                registry.register_by_string(table_name: table_name, string: table.join("\n"))
              end
            end
            subject { described_class.call(registry: registry, table_name: table_name, **given) }
            it { is_expected.to eq(expected) }
          end
        end
      end
    end
  end
end
