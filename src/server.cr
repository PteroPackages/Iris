module Iris
  class Server
    @id : String
    @uuid : String
    @client : Client
    @ws : HTTP::WebSocket
    @lf : File
    @df : File
    @events : Array(Event)
    getter log : Log

    def initialize(meta : ServerMeta, @client : Client, @lf : File, @df : File)
      @id = meta.identifier
      @uuid = meta.uuid
      @ws = uninitialized HTTP::WebSocket
      @events = [] of Event
      @log = ::Log.for(@id, :debug)

      log.info { "starting websocket connection" }
      reconnect
    end

    private def reconnect : Nil
      auth = @client.get_websocket_auth @id
      @ws = HTTP::WebSocket.new auth.socket, HTTP::Headers{"Origin" => @client.url}
      @ws.on_message { |msg| on_message msg }
      @ws.on_close { |code, msg| on_close code, msg }
      spawn @ws.run

      log.info { "sending auth token" }
      @ws.send Payload.new("auth", [auth.token]).to_json
    end

    def close : Nil
      @df.write @events.to_json.to_slice
      @df.close
      @lf.close
      log.debug { "closing" }
      @ws.close :going_away
    end

    private def on_message(message : String) : Nil
      # log.debug { message }
      payload = Payload.from_json message

      case payload.event
      when "auth success"
        log.info { "authentication successful" }
      when "console output", "daemon output"
        @lf.write payload.args.join('\n').to_slice
      when "daemon error"
        @events << Event.new(0, payload)
        @events << Event.new(1, "daemon error")
      when "install started"
        @events << Event.new(1, "install state start")
      when "install completed"
        @events << Event.new(1, "install state end")
      when "install output"
        @lf.write payload.args.join('\n').to_slice
      when "jwt error"
        log.error { payload.args.join }
        @events << Event.new(0, payload)
      when "stats"
        @events << Event.new(0, payload)
      when "status"
        @events << Event.new(0, payload)
      when "token expiring"
        auth = @client.get_websocket_auth @id
        @ws.send Payload.new("auth", [auth.token]).to_json
      when "token expired"
        @ws.close
        reconnect
      when "transfer logs"
        @lf.write payload.args.join('\n').to_slice
      when "transfer status"
        @events << Event.new(0, payload)
      else
        log.warn { "unknown event: #{payload.event}" }
      end
    end

    private def on_close(code : HTTP::WebSocket::CloseCode, message : String) : Nil
      log.debug &.emit("closed: #{message}", code: code.to_s)
    end
  end
end
