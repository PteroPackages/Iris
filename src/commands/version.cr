module Iris::Commands
  class Version < Cling::Command
    def setup : Nil
      @name = "version"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout.puts "iris version #{Iris::VERSION} [#{Iris::BUILD_HASH}] (#{Iris::BUILD_DATE})"
    end
  end
end
