module Gmshell
  class MessageContext
    def initialize(input:, handler_name:, **parameters)
      self.input = input.clone
      self.handler_name = handler_name.freeze
      self.parameters = parameters.freeze
    end

    include Comparable
    def <=>(other)
      hash <=> other.hash
    end

    def hash
      [input, handler_name, parameters].hash
    end

    attr_accessor :input, :handler_name, :parameters

    private :input=
    private :handler_name=
    private :parameters=
  end
end
