module Iris::Commands
  class Purge < Base
    def setup : Nil
      @name = "purge"

      add_argument "id"

      add_option 'y', "yes"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      Iris::Config.load_and_check
      path = Iris::Config::DATA_HOME / "data"
      if Dir.empty? path
        error "Nothing to purge"
        return
      end

      entries = [] of String

      Dir.children(path).each do |child|
        Dir.children(path / child).each do |date|
          entries << (path / child / date).to_s
        end
      end

      if date = options.get?("date").try &.as_s
        unless date.matches? /^\d{4}-\d{2}-\d{2}$/
          error "Invalid date format (should be yyyy-mm-dd)"
          return
        end

        entries.select! &.includes? date
      end

      if entries.empty?
        error "Nothing to purge"
        return
      end

      unless options.has?("yes")
        max_files = entries.sum { |f| Dir.children(f).size }
        max_size = entries.sum &->get_file_size(String)

        stdout << "Q: ".colorize.yellow
        stdout << "This will remove " << max_files << " file"
        stdout << "s" if max_files > 1
        stdout << " (" << max_size.humanize_bytes << ")\n"
        stdout << "Q: ".colorize.yellow
        stdout << "Do you want to continue? (y/n) "

        loop do
          answer = gets || ""
          case answer.downcase
          when "y", "ye", "yes"
            break
          when "n", "no"
            return
          else
            error "Invalid answer"
            stdout << "Q: ".colorize.yellow
            stdout << "Do you want to continue? (y/n) "
          end
        end
      end

      done = entries.count do |entry|
        Dir.children(entry).each { |f| File.delete f }
        Dir.delete entry

        true
      rescue
        false
      end

      done = 0
      entries.each do |entry|
        Dir.children(entry).each do |file|
          File.delete file
          done += 1
        rescue
          next
        end
      end

      stdout << "Deleted " << done << " file(s)\n"
    end

    private def get_file_size(path : String) : Int64
      if File.directory? path
        size = 0_i64
        Dir.each_child(path) do |child|
          size += get_file_size File.join(path, child)
        end

        size
      else
        File.size path
      end
    end
  end
end
