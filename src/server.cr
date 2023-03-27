module Iris
  class Server
    @id : String
    @meta : ServerMeta
    @client : Crest::Resource
    @ws : HTTP::WebSocket
    private getter log : Log

    def initialize(@meta, @client, origin)
      @id = @meta.identifier
      @log = ::Log.for(@id, :debug)

      log.info { "attempting to connect to websocket" }
      res = @client.get "/api/client/servers/#{@id}/websocket"
      auth = Auth.from_json(res.body).data

      @ws = HTTP::WebSocket.new auth.socket, HTTP::Headers{"Origin" => origin}
      @ws.on_message &->on_message(String)
      @ws.on_close &->on_close(HTTP::WebSocket::CloseCode, String)

      log.info { "sending auth token" }
      @ws.send Payload.new("auth", [auth.token]).to_json
      spawn @ws.run
    end

    private def reconnect : Nil
    end

    private def send_auth : Nil
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
      when "daemon error", "jwt error"
        log.error { payload.args.join }
      when "token expiring"
        send_auth
      when "token expired"
        reconnect
      end
    end

    private def on_close(code : HTTP::WebSocket::CloseCode, message : String) : Nil
      log.debug &.emit("closed: #{message}", code: code.to_s)
    end
  end
end
