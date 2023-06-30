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

      data.each do |meta|
        Log.info { "opening data log for #{meta.identifier}" }

        dir = Config::DATA_HOME / meta.uuid / Time.utc.to_s("%F")
        Dir.mkdir_p dir

        t = Time.utc.to_s "%s"
        lf = File.open(dir / "#{t}.log", mode: "w")
        df = File.open(dir / "#{t}.json", mode: "w")

        Log.info { "launching server #{meta.identifier}" }
        @servers << Server.new(meta, @client, lf, df)
      end

      Log.info { "launch complete, watching servers" }

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
