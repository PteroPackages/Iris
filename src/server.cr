module Iris
  class Server
    @id : String
    @meta : ServerMeta
    @client : Crest::Resource
    @ws : HTTP::WebSocket?
    @open : Bool
    private getter log : Log

    def initialize(@meta, @client)
      @id = @meta.identifier
      @log = ::Log.for(@id, :debug)
      @open = false
    end

    private def ws : HTTP::WebSocket
      @ws.not_nil!
    end

    def connect : Nil
      log.info { "attempting to connect to websocket" }

      res = @client.get "/api/client/servers/#{@id}/websocket"
      auth = AuthMeta.from_json(res.body).data

      @ws = HTTP::WebSocket.new auth.socket, HTTP::Headers{"Origin" => @client.url}
      ws.on_message &->on_message(String)
      ws.on_close &->on_close(HTTP::WebSocket::CloseCode, String)

      log.info { "starting connection to websocket" }

      spawn ws.run
      ws.send Payload.new("auth", [auth.token]).to_json
    end

    private def reconnect : Nil
    end

    private def send_auth : Nil
    end

    private def on_message(message : String) : Nil
      unless @open
        @open = true
        send_auth
      end

      log.debug { message }
      payload = Payload.from_json message

      case payload.event
      when "auth success"
        log.info { "authentication successful" }
      when "token expiring"
        send_auth
      when "token expired"
        reconnect
      end
    end

    private def on_close(code : HTTP::WebSocket::CloseCode, message : String) : Nil
      log.trace &.emit("closed: #{message}", code: code.to_s)
    end
  end
end
