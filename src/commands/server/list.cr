module Iris::Commands
  class List < Base
    class Result
      property path : String
      property data : Int32?
      property log : Int32?
      property size : String?

      def initialize(@path)
      end

      def bare? : Bool
        @data.nil? && @log.nil? && @size.nil?
      end
    end

    def setup : Nil
      @name = "list"
      @summary = "list stored servers"
      @description = <<-DESC
        Lists all the servers stored on the system. The output of this command can be
        customised using the options below. Results customised with the format flags
        will be displayed as a table.
        DESC

      add_usage "iris server list [-c|--count] [-d|--data] [-l|--log] [-p|--path] [-s|--size]"

      add_option 'c', "count", description: "display count of data and log files"
      add_option 'd', "data", description: "display count of data files"
      add_option 'l', "log", description: "display count of log files"
      add_option 'p', "path", description: "display the directory path"
      add_option 's', "size", description: "display the file size"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      root = Iris::Config::DATA_HOME / "data"
      data = options.has?("count") || options.has?("data")
      log = options.has?("count") || options.has?("log")
      path = options.has? "path"
      size = options.has? "size"
      results = [] of Result

      Dir.children(root).each do |uuid|
        result = Result.new uuid
        result.path = (root / uuid).to_s if path

        if data
          count = 0

          Dir.children(root / uuid).each do |date|
            Dir.each(root / uuid / date) do |file|
              count += 1 if file.ends_with? ".json"
            end
          end

          result.data = count
        end

        if log
          count = 0

          Dir.children(root / uuid).each do |date|
            Dir.each(root / uuid / date) do |file|
              count += 1 if file.ends_with? ".log"
            end
          end

          result.log = count
        end

        if size
          result.size = get_file_size(root / uuid).humanize_bytes
        end

        results << result
      end

      if results[0].bare?
        return results.each do |result|
          stdout.puts result.path
        end
      end

      if path
        path_size = results.max_of &.path.size
        stdout << "Path"
        stdout << " " * (path_size - 2)
      else
        stdout << "ID"
        stdout << " " * 36
      end

      stdout << "Data" if data
      if log
        stdout << "  " if data
        stdout << "Log"
      end
      if size
        stdout << "  " if data || log
        stdout << "Size"
      end
      stdout << '\n'

      results.each do |result|
        stdout << result.path << "  "

        if data
          stdout << result.data.to_s.ljust(5)
          stdout << " "
        end

        if log
          stdout << result.log.to_s.ljust(4)
          stdout << " "
        end

        stdout << result.size if size
        stdout << '\n'
      end
    end

    private def get_file_size(path : Path) : Int64
      if File.directory? path
        size = 0_i64
        Dir.each_child(path) do |child|
          size += get_file_size path / child
        end

        size
      else
        File.size path
      end
    end
  end
end
