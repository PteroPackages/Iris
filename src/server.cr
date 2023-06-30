module Iris
  class Server
    @id : String
    @uuid : String
    @client : Client
    @ws : HTTP::WebSocket
    getter log : Log

    def initialize(meta : ServerMeta, @client : Client)
      @id = meta.identifier
      @uuid = meta.uuid
      @ws = uninitialized HTTP::WebSocket
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
      # TODO: add log saving stuff
      log.debug { "closing" }
      @ws.close :going_away
    end

    private def on_message(message : String) : Nil
      log.debug { message }
      payload = Payload.from_json message

      case payload.event
      when "auth success"
        log.info { "authentication successful" }
      when "backup complete", "backup restore complete"
        return # handle these another time
      when "console output", "daemon output"
        # @console << payload.args.join '\n'
        # @records << Record.new("console", payload.args.join('\n'))
      when "daemon error"
        # @console << payload.args.join '\n'
        # @records << Record.new("error", payload.args.join)
      when "install started", "install completed"
        # @records << Record.new("install", payload.event)
      when "install output"
        # @console << payload.args.join '\n'
        # @records << Record.new("install", payload.args.join('\n'))
      when "jwt error"
        log.error { payload.args.join }
      when "stats"
        # @records << Record.new("stats", payload.args.join)
      when "status"
        # @records << Record.new("status", payload.args.first)
      when "token expired"
        reconnect
      when "token expiring"
        auth = @client.get_websocket_auth @id
        @ws.send Payload.new("auth", [auth.token]).to_json
      when "transfer logs", "transfer status"
        # @console << payload.args.join('\n') if payload.event == "transfer logs"
        # @records << Record.new("transfer", payload.args.join)
      else
        log.warn { "unknown event: #{payload.event}" }
      end
    end

    private def on_close(code : HTTP::WebSocket::CloseCode, message : String) : Nil
      log.debug &.emit("closed: #{message}", code: code.to_s)
    end
  end
end
