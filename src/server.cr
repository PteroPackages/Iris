module Iris
  struct Auth
    include JSON::Serializable

    getter socket : String
    getter token : String
  end

  class Server
    @id : String
    @uri : URI
    @ws : HTTP::WebSocket?

    def initialize(@id, @uri)
    end

    private def ws : HTTP::WebSocket
      @ws.not_nil!
    end

    def connect : Nil
      # auth = Manager.get_auth_data @id
    end
  end
end
