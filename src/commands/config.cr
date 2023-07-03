module Iris::Commands
  class Config < Base
    def setup : Nil
      @name = "config"
      @summary = "iris config management"
      @description = "Shows the current config or modifies fields with the given flags."

      add_usage "fossil config [command] [--url <url>] [--key <key>] [options]"
      add_usage "fossil config add-server <ids...>"
      add_usage "fossil config del-server <ids...>"

      add_command AddServer.new
      add_command DelServer.new

      add_option "url", description: "the url to set", type: :single
      add_option "key", description: "the key to set", type: :single
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Iris::Config.load

      if options.empty?
        stdout << "url: " << config.panel_url << '\n'
        stdout << "key: " << config.panel_key << '\n'

        stdout << "\nservers:"
        if config.servers.empty?
          stdout << " none\n"
        else
          config.servers.each do |id|
            stdout << "\n - " << id
          end
          stdout << '\n'
        end

        stdout << "\nextensions:"
        if config.extensions.empty?
          stdout << " none\n"
        else
          config.extensions.each do |id|
            stdout << "\n - " << id
          end
        end

        return
      end

      if url = options.get?("url")
        config.panel_url = url.as_s
      end

      if key = options.get?("key")
        config.panel_key = key.as_s
      end

      config.save
    end
  end

  class AddServer < Base
    def setup : Nil
      @name = "add-server"
      @summary = "add a server to the config"
      @description = "Adds one or more servers' identifier to the Iris configuration."

      add_usage "iris config add-server <ids...>"

      add_argument "ids", multiple: true
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Iris::Config.load
      ids = arguments.get("ids").as_set
      config.servers += ids
      config.save
    end
  end

  class DelServer < Base
    def setup : Nil
      @name = "del-server"
      @summary = "remove a server from the config"
      @description = "Removes one or more servers' identifier from the Iris configuration."

      add_usage "iris config del-server <ids...>"

      add_argument "ids", multiple: true
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Iris::Config.load
      ids = arguments.get("ids").as_set
      config.servers -= ids
      config.save
    end
  end
end
