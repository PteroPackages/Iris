require "./iris"

class App < Cling::Command
  def setup : Nil
    @name = "iris"
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    Iris::Manager.launch
  end
end

App.new.execute ARGV
