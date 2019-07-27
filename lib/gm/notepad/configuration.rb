require 'gm/notepad/defaults'
module Gm
  module Notepad
    # Global configuration values
    class Configuration
      CLI_CONFIG_DEFAULTS = {
        report_config: false,
        defer_output: false,
        filesystem_directory: '.',
        interactive_buffer: $stderr,
        interactive_color: true,
        output_color: false,
        list_tables: false,
        output_buffer: $stdout,
        paths: ['.'],
        column_delimiter: Gm::Notepad::DEFAULT_COLUMN_DELIMITER,
        shell_prompt: Gm::Notepad::DEFAULT_SHELL_PROMPT,
        skip_readlines: false,
        table_extension: '.txt',
        with_timestamp: false
      }.freeze

      def self.defaults_for(*keys)
        CLI_CONFIG_DEFAULTS.slice(*keys)
      end

      # NOTE: ORDER MATTERS! I have a temporal dependency in these
      # defaults
      INTERNAL_CONFIG_DEFAULTS_METHOD_NAMES = [
        :table_registry,
        :input_handler_registry,
        :input_processor,
        :renderer,
      ]

      def self.init!(target:, from_config:, &block)
        target.define_method(:initialize) do |config:|
          @config = config
          from_config.each do |method_name|
            send("#{method_name}=", @config[method_name])
          end
          instance_exec(&block) if block
        end
        from_config.each do |method_name|
          target.attr_accessor(method_name)
          protected "#{method_name}="
        end
        target.attr_reader :config
      end

      def initialize(input_handler_registry: nil, table_registry: nil, renderer: nil, input_processor: nil, **overrides)
        # INTERNAL_CONFIG_DEFAULTS_METHOD_NAMES.each do |method_name|
        #   send("#{method_name}=", (overrides[method_name] || send("default_#{method_name}")))
        #   overrides.delete(method_name)
        # end

        CLI_CONFIG_DEFAULTS.each_pair do |key, default_value|
          value = overrides.fetch(key, default_value)
          if !value.is_a?(IO)
            value = value.clone
            value.freeze
          end
          self.send("#{key}=", value)
        end
        self.table_registry = (table_registry || default_table_registry)
        self.input_handler_registry = (input_handler_registry || default_input_handler_registry)
        self.renderer = (renderer || default_renderer)
        self.input_processor = (input_processor || default_input_processor)
      end
      attr_reader(*CLI_CONFIG_DEFAULTS.keys)
      attr_reader(*INTERNAL_CONFIG_DEFAULTS_METHOD_NAMES)

      def to_hash
        config = CLI_CONFIG_DEFAULTS.keys.each_with_object({}) do |key, mem|
          mem[key] = send(key)
        end
        INTERNAL_CONFIG_DEFAULTS_METHOD_NAMES.each_with_object(config) do |key, mem|
          mem[key] = send(key)
        end
      end

      def [](value)
        public_send(value)
      end

      private
      attr_writer(*CLI_CONFIG_DEFAULTS.keys)
      attr_writer(*INTERNAL_CONFIG_DEFAULTS_METHOD_NAMES)

      def default_input_processor
        require "gm/notepad/input_processor"
        InputProcessor.new(config: self)
      end

      def default_table_registry
        require "gm/notepad/table_registry"
        TableRegistry.load_for(config: self)
      end

      def default_renderer
        require 'gm/notepad/line_renderer'
        LineRenderer.new(config: self)
      end

      def default_input_handler_registry
        require "gm/notepad/input_handler_registry"
        require "gm/notepad/input_handlers/help_handler"
        require "gm/notepad/input_handlers/comment_handler"
        require "gm/notepad/input_handlers/query_table_handler"
        require "gm/notepad/input_handlers/query_table_names_handler"
        require "gm/notepad/input_handlers/write_to_table_handler"
        require "gm/notepad/input_handlers/write_line_handler"
        InputHandlerRegistry.new do |registry|
          registry.register(handler: InputHandlers::HelpHandler)
          registry.register(handler: InputHandlers::CommentHandler)
          registry.register(handler: InputHandlers::QueryTableHandler)
          registry.register(handler: InputHandlers::QueryTableNamesHandler)
          registry.register(handler: InputHandlers::WriteToTableHandler)
          registry.register(handler: InputHandlers::WriteLineHandler)
        end
      end
    end
  end
end
