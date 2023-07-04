module Iris
  struct Fractal(M)
    include JSON::Serializable

    getter attributes : M
  end

  struct Event
    include JSON::Serializable

    getter op : UInt8
    getter d : Payload?
    getter t : Int64

    def self.new(op : UInt8)
      new op, nil
    end

    def initialize(@op, @d)
      @t = Time.utc.to_unix
    end
  end

  struct Payload
    include JSON::Serializable

    getter event : String
    getter args : Array(String) = [] of String

    def initialize(@event, @args)
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

  struct WebSocketAuth
    include JSON::Serializable

    struct Data
      include JSON::Serializable

      getter socket : String
      getter token : String
    end

    getter data : Data
  end
end
