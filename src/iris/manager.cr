module Iris
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
        Log.error(exception: ex) { "failed to fetch server metadata" }
      end

      data.each do |meta|
        Log.debug { "opening data log: #{meta.uuid}" }

        dir = Config::DATA_HOME / "data" / meta.uuid / Time.utc.to_s("%F")
        Dir.mkdir_p dir

        t = Time.utc.to_s "%s"
        lf = File.open(dir / "#{t}.log", mode: "w")
        df = File.open(dir / "#{t}.json", mode: "w")

        Log.info { "launching server: #{meta.identifier}" }
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
