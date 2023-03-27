module Iris
  struct Auth
    include JSON::Serializable

    getter data : AuthData
  end

  struct AuthData
    include JSON::Serializable

    getter socket : String
    getter token : String
  end

  struct Fractal(M)
    include JSON::Serializable

    getter attributes : M
  end

  struct Payload
    include JSON::Serializable

    getter event : String
    getter args : Array(String)

    def initialize(@event : String, @args : Array(String))
    end
  end

  struct ServerMeta
    include JSON::Serializable

    getter identifier : String
    getter uuid : String
    getter name : String
    getter status : String?
    getter? is_node_under_maintenance : Bool
  end
end
