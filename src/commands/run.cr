module Iris::Commands
  class Run < Base
    def setup : Nil
      @name = "run"
      @summary = "launch iris manager"
      @description = <<-DESC
        Launches the Iris manager. This will connect to all the servers set in the Iris
        configuration and stream server events and logs to the server's data path on
        the system.
        DESC

      add_usage "iris run [--debug]"

      add_option "debug", description: "show debug information"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      Manager.launch options.has?("debug")
    end
  end
end
