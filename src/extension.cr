module Iris
  class Extension
    ROOT      = Config::DATA_HOME / "extensions"
    CALLBACKS = {
      "on_stats_update",
      "on_status_update",
    }

    @log : ::Log
    @names : Set(String)
    @lua : Lua::Stack
    @callbacks : Hash(String, Array(Lua::Function))

    def initialize(@names : Set(String), debug : Bool)
      @log = ::Log.for(self, debug ? Log::Severity::Debug : Log::Severity::Info)
      @lua = Lua.load
      @callbacks = Hash(String, Array(Lua::Function)).new do |hash, key|
        hash[key] = [] of Lua::Function
      end
    end

    def load : Nil
      @log.info { "loading extensions" }
      @names.each { |n| load n }
    end

    def load(name : String) : Nil
      @log.debug { "loading extension: #{name}" }
      unless name.ends_with? ".lua"
        @log.warn { "extension name should end with .lua" }
      end

      unless File.exists? ROOT / name
        @log.error { "extension not found: #{name}" }
        return
      end

      File.open(ROOT / name) do |file|
        res = @lua.run file
        unless res.is_a? Lua::Table
          @log.error { "expected extension to return a table of functions" }
          return
        end

        res.as(Lua::Table).to_h.each do |key, value|
          unless key.is_a? String
            @log.error { "expected table key to be a string" }
            next
          end

          unless CALLBACKS.includes? key
            @log.warn { "unknown callback function: #{key}" }
            next
          end

          unless value.is_a? Lua::Function
            @log.error { "expected table key-value to be a function" }
            next
          end

          @log.debug { "adding callback: #{key}" }
          @callbacks[key] << value
        end
      rescue ex : Lua::LuaError
        @log.error(exception: ex) { "failed to load extension: #{name}" }
      end
    end

    def close : Nil
      @lua.close
    end
  end
end
