module Iris
  class Server
    @id : String
    @uuid : String
    @client : Client
    @ws : HTTP::WebSocket

    @lf : File
    @df : File
    getter log : Log

    def initialize(meta : ServerMeta, debug : Bool, @client : Client, @lf : File, @df : File)
      @id = meta.identifier
      @uuid = meta.uuid
      @ws = uninitialized HTTP::WebSocket
      @df.write_byte 91
      @df.write Event.new(0).to_json.to_slice
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
      @df.write Event.new(0).to_json.to_slice
      @df.write_byte 93
      @df.close
      @ws.close :going_away
    end

    private def on_message(message : String) : Nil
      payload = Payload.from_json message
      log.debug { "incoming: #{payload.event}" }

      case payload.event
      when "auth success"
        log.info { "authentication successful" }
      when "console output", "daemon output"
        write_log payload
      when "daemon error"
        write_event "daemon error"
        write_event payload
      when "install started"
        write_event "install started"
      when "install completed"
        write_event "install completed"
      when "install output"
        write_log payload
        write_event payload
      when "jwt error"
        log.error { payload.args.join }
        write_event payload
      when "stats"
        write_event payload
      when "status"
        write_event payload
      when "token expiring"
        log.info { "reauthenticating" }
        auth = @client.get_websocket_auth @id
        @ws.send Payload.new("auth", [auth.token]).to_json
      when "token expired"
        log.info { "session expired, reconnecting" }
        @ws.close
        reconnect
      when "transfer logs"
        write_event payload
      when "transfer status"
        write_event payload
      else
        log.warn { "unknown event: #{payload.event}" }
      end
    end

    private def write_log(d : Payload) : Nil
      @lf.write d.args.join('\n').to_slice
      @lf.write_byte 10
    end

    private def write_event(d : String) : Nil
      @df.write_byte 44
      @df.write Event.new(1, d).to_json.to_slice
    end

    private def write_event(d : Payload) : Nil
      @df.write_byte 44
      @df.write Event.new(2, d).to_json.to_slice
    end

    private def on_close(code : HTTP::WebSocket::CloseCode, message : String) : Nil
      log.debug &.emit("closed: #{message}", code: code.to_s)
    end
  end
end
