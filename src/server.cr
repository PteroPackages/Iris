module Iris
  class Server
    @id : String
    @origin : String
    @meta : ServerMeta
    @client : Crest::Resource
    @ws : HTTP::WebSocket

    getter records : Array(Record)
    getter console : IO::Memory
    private getter log : Log

    def initialize(@meta, @client, @origin : String, debug : Bool)
      @id = @meta.identifier
      @records = [] of Record
      @console = IO::Memory.new
      @ws = uninitialized HTTP::WebSocket
      @log = ::Log.for(@id, debug ? Log::Severity::Debug : nil)

      log.info { "attempting to connect to websocket" }
      reconnect
    end

    private def reconnect : Nil
      res = @client.get "/api/client/servers/#{@id}/websocket"
      auth = Auth.from_json(res.body).data

      @ws = HTTP::WebSocket.new auth.socket, HTTP::Headers{"Origin" => @origin}
      @ws.on_message &->on_message(String)
      @ws.on_close &->on_close(HTTP::WebSocket::CloseCode, String)

      log.info { "sending auth token" }
      @ws.send Payload.new("auth", [auth.token]).to_json
      spawn @ws.run
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
        @console << payload.args.join '\n'
        @records << Record.new("console", payload.args.join('\n'))
      when "daemon error"
        @console << payload.args.join '\n'
        @records << Record.new("error", payload.args.join)
      when "install started", "install completed"
        @records << Record.new("install", payload.event)
      when "install output"
        @console << payload.args.join '\n'
        @records << Record.new("install", payload.args.join('\n'))
      when "jwt error"
        log.error { payload.args.join }
      when "stats"
        @records << Record.new("stats", payload.args.join)
      when "status"
        @records << Record.new("status", payload.args.first)
      when "token expired"
        reconnect
      when "token expiring"
        res = @client.get "/api/client/servers/#{@id}/websocket"
        auth = Auth.from_json(res.body).data

        @ws.send Payload.new("auth", [auth.token]).to_json
      when "transfer logs", "transfer status"
        @console << payload.args.join('\n') if payload.event == "transfer logs"
        @records << Record.new("transfer", payload.args.join)
      else
        log.warn { "unknown event: #{payload.event}" }
      end
    end

    private def on_close(code : HTTP::WebSocket::CloseCode, message : String) : Nil
      log.debug &.emit("closed: #{message}", code: code.to_s)
    end
  end
end
