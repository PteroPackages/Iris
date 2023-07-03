module Iris::Commands
  class Server < Base
    def setup : Nil
      @name = "server"
      @summary = "iris server management"

      add_usage "iris server [options]"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      root = Iris::Config::DATA_HOME
      ext = root / "extensions"

      str = String.build do |io|
        io << "directory: " << root << '\n'
        io << "extensions:"

        if Dir.exists? ext
          if Dir.empty? ext
            io << " none\n"
          else
            Dir.children(ext).each do |child|
              io << "\n- " << child
            end
            io << '\n'
          end
        end

        total, empty, logs, data = get_total_metadata
        io << "\ntotal servers: " << total
        unless empty.zero?
          io << " (" << empty << " empty servers)"
        end
        io << "\ntotal logs: " << logs
        io << "\ntotal data: " << data << '\n'
      end

      stdout.puts str
    end

    private def get_total_metadata : {Int32, Int32, Int32, Int32}
      path = Iris::Config::DATA_HOME / "data"
      return {0, 0, 0, 0} if !Dir.exists?(path) || Dir.empty?(path)

      total = empty = logs = data = 0
      Dir.children(path).each do |uuid|
        total += 1
        if Dir.empty? path / uuid
          empty += 1
          next
        end

        Dir.children(path / uuid).each do |date|
          next if Dir.empty? path / uuid / date

          Dir.each(path / uuid / date) do |file|
            logs += 1 if file.ends_with? ".log"
            data += 1 if file.ends_with? ".json"
          end
        end
      end

      {total, empty, logs, data}
    end
  end
end
