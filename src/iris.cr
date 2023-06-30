require "cling"
require "colorize"
require "crest"
require "http/headers"
require "http/web_socket"
require "json"
require "log"
require "yaml"

require "./client"
require "./config"
require "./models"
require "./server"

Colorize.on_tty_only!

module Iris
  VERSION = "0.1.0"

  class Manager
    Log = ::Log.for(self, :debug)

    @config : Config
    @client : Client
    @servers : Array(Server)

    def self.launch : Nil
      new Config.load_and_check
    end

    private def initialize(@config : Config)
      @client = Client.new @config.panel_url, @config.panel_key
      @servers = [] of Server

      launch
    end

    private def launch : Nil
      Log.info { "testing panel connection" }

      begin
        @client.test_connection
      rescue ex : Crest::RequestFailed
        Log.fatal(exception: ex) { "failed to connect to the panel" }
        exit 1
      end

      data = [] of ServerMeta
      @config.servers.each do |id|
        Log.info { "fetching data for server: #{id}" }

        meta = @client.get_server id
        if meta.status == "suspended" || meta.is_node_under_maintenance?
          Log.warn { "server #{id} is not accessible right now" }
          next
        end

        data << meta
      rescue ex : Crest::RequestFailed
        Log.error(exception: ex) { "failed to fetch server meta" }
      end

      Log.info { "launching #{data.size} servers" }
      data.each { |meta| @servers << Server.new(meta, @client) }
      Log.info { "launch completed, watching servers" }

      sig = Channel(Nil).new
      Process.on_interrupt do
        Log.info { "closing #{data.size} server connections" }
        @servers.each &.close
        sig.send nil
      end

      sig.receive
    end
  end
end
