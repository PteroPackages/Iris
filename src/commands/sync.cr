module Iris::Commands
  class Sync < Base
    def setup : Nil
      @name = "sync"
      @summary = "sync iris configuration"
      @description = <<-DESC
        Syncs the Iris configuration with the running instance (that is on the
        configured host and port). Note that this will not work if the host or port in
        the configuration is changed.
        DESC

      add_usage "iris sync"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Iris::Config.load
      socket = TCPSocket.new config.host, config.port

      socket << "sync\n"
      res = socket.gets
      unless res == "done"
        error "failed to sync running instance:"
        error res
      end

      socket.close
    rescue Socket::ConnectError
      error "no running instance available"
    end
  end
end
