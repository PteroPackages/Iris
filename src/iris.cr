require "cling"
require "cling/ext"
require "colorize"
require "crest"
require "http/headers"
require "http/web_socket"
require "json"
require "log"
require "lua"
require "socket"
require "yaml"

require "./client"
require "./commands/*"
require "./config"
require "./extension"
require "./manager"
require "./models"
require "./server"

Colorize.on_tty_only!

module Iris
  VERSION    = "0.1.0"
  BUILD_DATE = {% if flag?(:win32) %}
                {{ `powershell.exe -NoProfile Get-Date -Format "yyyy-MM-dd"`.stringify.chomp }}
               {% else %}
                {{ `date +%F`.stringify.chomp }}
               {% end %}

  BUILD_HASH = {{ `git rev-parse HEAD`.stringify[0...8] }}

  class App < Commands::Base
    def setup : Nil
      @name = "iris"
      @description = "A Pterodactyl server monitor."

      add_usage "iris <command> [options]"

      add_command Commands::Server.new
      add_command Commands::Run.new
      add_command Commands::Sync.new
      add_command Commands::Config.new
      add_command Commands::Env.new
      add_command Commands::Version.new
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout.puts help_template
    end
  end
end

Iris::App.new.execute ARGV
