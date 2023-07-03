module Iris::Commands
  class Env < Base
    def setup : Nil
      @name = "env"
      @summary = "iris environment display"
      @description = <<-DESC
        Displays the Iris environment/system paths. Specify the "data" argument to
        display the data path, or specify "ext", "extension" or "extensions" argument
        to display the extensions path.
        DESC

      add_usage "iris env [name]"

      add_argument "name"
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
