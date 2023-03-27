require "cling"
require "colorize"
require "crest"
require "http/headers"
require "http/web_socket"
require "json"
require "log"
require "yaml"

require "./config"
require "./models"
require "./server"

Colorize.on_tty_only!

module Iris
  VERSION = "0.1.0"

  class Manager
    Log = ::Log.for(self, :debug)

    @config : Config
    @client : Crest::Resource
    @servers : Array(Server) = [] of Server

    private def initialize(@config : Config)
      @client = Crest::Resource.new(
        @config.url,
        headers: {"Authorization" => "Bearer #{@config.key}",
                  "Content-Type"  => "application/json",
                  "Accept"        => "application/json"}
      )
      @servers = [] of Server

      launch
    end

    def self.launch : Nil
      new Config.load
    end

    private def launch : Nil
      Log.fatal { "no server identifiers specified" } if @config.servers.empty?
      Log.info { "testing panel connection" }
      Log.debug { "using origin: #{@config.url}" }

      begin
        @client.head "/api/client"
      rescue ex : Crest::RequestFailed
        Log.fatal(exception: ex) { "failed to connect to the panel" }
        exit 1
      end

      data = [] of ServerMeta
      @config.servers.each do |id|
        Log.info { "fetching data for server: #{id}" }

        meta = fetch_server id
        if meta.status == "suspended" || meta.is_node_under_maintenance?
          Log.warn { "server #{id} is not accessible right now" }
          next
        end

        data << meta
      rescue ex : Crest::RequestFailed
        Log.error(exception: ex) { "failed to fetch server meta" }
      end

      Log.info { "launching #{data.size} servers" }
      data.each do |meta|
        server = Server.new meta, @client, @config.url
        @servers << server
      end

      Log.info { "launch completed, watching servers" }
      at_exit do
        Log.info { "closing #{data.size} server connections" }
        @servers.map &.close
      end

      sig = Channel(Nil).new
      loop do
        sig.send(nil) if sig.receive
      end
    end

    private def fetch_server(id : String) : ServerMeta
      res = @client.get "/api/client/servers/#{id}"
      data = Fractal(ServerMeta).from_json res.body

      data.attributes
    end
  end

  class App < Cling::Command
    def setup : Nil
      @name = "iris"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      Manager.launch
    end
  end
end
