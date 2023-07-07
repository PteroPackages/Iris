module Iris
  class Manager
    Log = ::Log.for(self, :debug)

    @config : Config
    @client : Client
    @servers : Array(Server)
    @sync : Bool

    def self.launch(debug : Bool) : Nil
      new Config.load_and_check, debug
    end

    private def initialize(@config : Config, debug : Bool)
      @client = Client.new @config.panel_url, @config.panel_key
      @servers = [] of Server
      @sync = false

      launch debug
    end

    private def launch(debug : Bool) : Nil
      Log.info { "establishing server connection: #{@config.host}:#{@config.port}" }
      server = TCPServer.new @config.host, @config.port

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
        Log.info { "opening data log: #{meta.uuid}" }

        dir = Config::DATA_HOME / "data" / meta.uuid / Time.utc.to_s("%F")
        Dir.mkdir_p dir

        t = Time.utc.to_s "%s"
        lf = File.open(dir / "#{t}.log", mode: "w")
        df = File.open(dir / "#{t}.json", mode: "w")

        Log.info { "launching server: #{meta.identifier}" }
        @servers << Server.new(meta, debug, @config, lf, df)
      end

      Log.info { "launch complete, watching servers" }

      Process.on_interrupt do
        server.close
        @servers.each &.close
      end

      loop do
        if socket = server.accept?
          spawn handle_connection socket
        else
          break
        end
      end
    end

    private def handle_connection(socket : TCPSocket) : Nil
      Log.info { "new socket connection: #{socket.remote_address}" }

      # FIXME: This is faulty
      # until socket.closed?
      case socket.gets
      when "sync"
        if @sync
          socket << "error:already syncing"
        else
          Log.info { "processing sync request" }
          @sync = true

          begin
            @config = Config.load_and_check
            socket << "done\n"
          rescue ex
            socket << "error: #{ex}"
          end

          @sync = false
        end
      else
        socket << "error:bad request\n"
      end
      # end

      Log.info { "socket connection closed: #{socket.remote_address}" }
    end
  end
end
