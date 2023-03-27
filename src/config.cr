module Iris
  struct Config
    include YAML::Serializable

    getter url : String
    getter key : String # TODO: replace with custom JWT impl
    getter? debug : Bool
    getter data : String
    getter servers : Array(String)

    def self.load : Config
      path = case
             when File.exists? "iris.yml"
               "iris.yml"
             when File.exists? "iris.yaml"
               "iris.yaml"
             else
               raise "cannot find config file"
             end

      from_yaml File.read path
    end
  end
end
