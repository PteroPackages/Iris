module Iris
  struct Config
    include YAML::Serializable

    DATA_HOME = begin
      {% if flag?(:win32) %}
        Path[ENV["APPDATA"]] / "iris"
      {% else %}
        if data = ENV["XDG_DATA_HOME"]?
          Path[data] / "iris"
        else
          Path.home / ".local" / "share" / "iris"
        end
      {% end %}
    end

    getter panel_url : String
    getter panel_key : String
    getter servers : Array(String)
    getter extensions : Array(String)

    def self.load : Config
      from_yaml File.read(DATA_HOME / "config.yml")
    end

    def self.load_and_check : Config
      unless Dir.exists? DATA_HOME / "data"
        Dir.mkdir_p DATA_HOME / "data"
      end

      unless Dir.exists? DATA_HOME / "extensions"
        Dir.mkdir_p DATA_HOME / "extensions"
      end

      cfg = load
      _ = URI.parse cfg.panel_url

      # TODO: maybe replace with error enums design
      raise "invalid panel api key" unless cfg.panel_key.starts_with? "ptlc_"
      raise "no servers specified" if cfg.servers.empty?

      # TODO: check and laod extensions
      cfg
    end
  end
end
