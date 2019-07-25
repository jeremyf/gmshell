require 'time'
require_relative 'message_handlers/query_handler'
require_relative 'message_handlers/tables_query_handler'
require_relative 'message_handlers/write_line_handler'

module Gmshell
  # Responsible for recording entries and then dumping them accordingly.
  class Notepad
    attr_reader :config
    def initialize(**config)
      self.config = config
      self.timestamp = config.fetch(:timestamp) { true }
      self.io = config.fetch(:io) { default_io }
      self.logger = config.fetch(:logger) { default_logger }
      self.table_registry = config.fetch(:table_registry) { default_table_registry }
      self.message_factory = config.fetch(:message_factory) { default_message_factory }
      @lines = []
    end

    HANDLERS = {
      query: Gmshell::MessageHandlers::QueryHandler.method(:handle),
      tables_query: Gmshell::MessageHandlers::TablesQueryHandler.method(:handle),
      write_line: Gmshell::MessageHandlers::WriteLineHandler.method(:handle)
    }

    HELP_REGEXP = /\A\?(?<help_with>.*)/
    def process(line:)
      handler_name, parameters = message_factory.call(line: line.to_s.strip)
      handler = HANDLERS.fetch(handler_name) { method(:record) }
      handler.call(notepad: self, **parameters)
    end

    def record(line:, as_of: Time.now, **kwargs)
      log(line, capture: true, expand: true)
    end

    def log(lines, expand: true, capture: false)
      Array(lines).sort.each do |line|
        line = table_registry.evaluate(line: line.to_s.strip) if expand
        logger.puts("=>\t#{line}")
        if capture
          @lines << line
        end
      end
    end

    def table_for(*args)
      table_registry.table_for(*args)
    end

    def terms(*args)
      table_registry.terms(*args)
    end

    def dump!
      if !config[:skip_config_reporting]
        @io.puts "# Configuration Parameters:"
        config.each do |key, value|
          @io.puts "#   config[#{key.inspect}] = #{value.inspect}"
        end
      end
      @lines.each do |line|
        io.puts line
      end
    end

    attr_reader :table_registry

    private

    attr_accessor :io, :logger, :timestamp, :message_factory
    attr_writer :config, :table_registry

    alias timestamp? timestamp

    def default_message_factory
      require_relative "message_factory"
      MessageFactory.new
    end

    def default_table_registry
      require_relative "table_registry"
      TableRegistry.load_for(paths: config.fetch(:paths, []))
    end

    def default_io
      $stdout
    end

    def default_logger
      $stderr
    end
  end
end
