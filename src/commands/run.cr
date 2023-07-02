module Iris::Commands
  class Run < Cling::Command
    def setup : Nil
      @name = "run"

      add_option "debug"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      Manager.launch options.has?("debug")
    end
  end
end
