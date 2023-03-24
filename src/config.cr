module Iris
  class Config
    include YAML::Serializable

    property url : String
    property key : String # TODO: replace with custom JWT impl
  end
end
