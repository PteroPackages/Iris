module Iris
  class Client
    @rest : Crest::Resource
    getter url : String

    HEADERS = {
      "User-Agent"   => "iris client #{Iris::VERSION}",
      "Content-Type" => "application/json",
      "Accept"       => "application/json",
    }

    def initialize(@url : String, key : String)
      HEADERS["Authorization"] = "Bearer #{key}"
      @rest = Crest::Resource.new(@url, headers: HEADERS)
    end

    def test_connection : Nil
      @rest.head "/api/client"
    end

    def get_server(id : String) : ServerMeta
      res = @rest.get "/api/client/servers/#{id}"
      body = Fractal(ServerMeta).from_json res.body

      body.attributes
    end

    def get_websocket_auth(id : String) : WebSocketAuth::Data
      res = @rest.get "/api/client/servers/#{id}/websocket"

      WebSocketAuth.from_json(res.body).data
    end
  end
end
