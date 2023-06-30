require "cling"
require "colorize"
require "crest"
require "http/headers"
require "http/web_socket"
require "json"
require "log"
require "yaml"

require "./commands/*"
require "./iris/*"

Colorize.on_tty_only!

module Iris
  VERSION = "0.1.0"

  class App < Cling::Command
    def setup : Nil
      @name = "iris"

      add_command Commands::Config.new
      add_command Commands::Env.new
      add_command Commands::Run.new
      add_command Commands::Version.new
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    end
  end
end

Iris::App.new.execute ARGV
