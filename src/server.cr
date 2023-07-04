module Iris
  class Server
    @id : String
    @uuid : String
    @client : Client
    @ws : HTTP::WebSocket

    @lf : File
    @df : File
    getter log : Log

    def initialize(meta : ServerMeta, debug : Bool, config : Config, @lf : File, @df : File)
      @id = meta.identifier
      @uuid = meta.uuid
      @client = Client.new config.panel_url, config.panel_key
      @ws = uninitialized HTTP::WebSocket
      @df.write_byte 91
      @df.write Event.new(0u8).to_json.to_slice
      @log = ::Log.for(@id, debug ? Log::Severity::Debug : Log::Severity::Info)

      log.info { "starting websocket connection" }
      reconnect
    end

    private def reconnect : Nil
      log.debug { "fetching websocket auth" }
      auth = @client.get_websocket_auth @id

      @ws = HTTP::WebSocket.new auth.socket, HTTP::Headers{"Origin" => @client.url}
      @ws.on_message { |msg| on_message msg }
      @ws.on_close { |code, msg| on_close code, msg }

      log.debug { "starting websocket listener" }
      spawn @ws.run

      log.debug { "sending auth token" }
      @ws.send Payload.new("auth", [auth.token]).to_json
    end

    def close : Nil
      log.info { "closing files and connection" }
      @lf.close
      @df.write_byte 44
      @df.write Event.new(0u8).to_json.to_slice
      @df.write_byte 93
      @df.close
      @ws.close :going_away
    end

    private def on_message(message : String) : Nil
      payload = Payload.from_json message

      case payload.event
      when "console output", "install output", "transfer logs", "daemon message"
        write_log payload
      when "token expiring"
        log.info { "reauthenticating" }
        auth = @client.get_websocket_auth @id
        @ws.send Payload.new("auth", [auth.token]).to_json
      when "token expired"
        log.info { "session expired, reconnecting" }
        @ws.close
        reconnect
      end

      write_event payload
    end

    private def write_log(d : Payload) : Nil
      @lf.write d.args.join('\n').to_slice
      @lf.write_byte 10
    end

    private def write_event(d : Payload) : Nil
      @df.write_byte 44
      @df.write Event.new(1u8, d).to_json.to_slice
    end

    private def on_close(code : HTTP::WebSocket::CloseCode, message : String) : Nil
      log.debug &.emit("closed: #{message}", code: code.to_s)
    end
  end
end
