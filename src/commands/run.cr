module Iris::Commands
  class Run < Cling::Command
    def setup : Nil
      @name = "run"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      Manager.launch
    end
  end
end
