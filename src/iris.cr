require "cling"
require "colorize"
require "crest"
require "http/headers"
require "http/web_socket"
require "json"
require "log"
require "yaml"

require "./config"
require "./server"

Colorize.on_tty_only!

module Iris
  VERSION = "0.1.0"

  module Manager
    Log = ::Log.for(self)

    @@servers : Array(Server) = [] of Server

    def self.launch : Nil
    end
  end

  class App < Cling::MainCommand
    def setup : Nil
      @name = "iris"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      Manager.launch
    end
  end
end
