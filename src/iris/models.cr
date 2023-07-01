module Iris
  struct Fractal(M)
    include JSON::Serializable

    getter attributes : M
  end

  struct Event
    include JSON::Serializable

    getter op : Int8
    getter d : Int64 | {String, Int64} | Payload

    def self.new(op : Int8)
      new op, Time.utc.to_unix
    end

    def self.new(op : Int8, d : String)
      new op, {d, Time.utc.to_unix}
    end

    def initialize(@op, @d)
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
