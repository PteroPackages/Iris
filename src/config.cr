module Iris
  class Config
    include YAML::Serializable

    property url : String
    property key : String # TODO: replace with custom JWT impl
    property data : String
    property servers : Array(String)

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
