module Iris::Commands
  class Env < Cling::Command
    def setup : Nil
      @name = "env"

      add_argument "name", required: false
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      root = Iris::Config::DATA_HOME

      if name = arguments.get?("name")
        case name.as_s
        when "data"
          stdout.puts root / "data"
        when "ext", "extension", "extensions"
          stdout.puts root / "extensions"
        end
      else
        stdout.puts <<-ENV
          data: #{root / "data"}
          extensions: #{root / "extensions"}
          ENV
      end
    end
  end
end
