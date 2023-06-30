require "cling"
require "colorize"
require "crest"
require "http/headers"
require "http/web_socket"
require "json"
require "log"
require "yaml"

require "./iris/*"

Colorize.on_tty_only!

module Iris
  VERSION = "0.1.0"

  class App < Cling::Command
    def setup : Nil
      @name = "iris"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      Manager.launch
    end
  end
end

Iris::App.new.execute ARGV
