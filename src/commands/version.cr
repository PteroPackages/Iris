module Iris::Commands
  class Version < Base
    def setup : Nil
      @name = "version"
      @summary = "get version information"
      @description = "Shows the version information for Iris."

      add_usage "iris version"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout.puts "iris version #{Iris::VERSION} [#{Iris::BUILD_HASH}] (#{Iris::BUILD_DATE})"
    end
  end
end
