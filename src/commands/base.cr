module Iris::Commands
  abstract class Base < Cling::Command
    def initialize
      super

      @inherit_options = true
      add_option "no-color", description: "disable ansi color codes"
      add_option 'h', "help", description: "get help information"
    end

    def help_template : String
      String.build do |io|
        io << @description << "\n\n"

        io << "Usage:".colorize.cyan << '\n'
        @usage.each do |use|
          io << use << '\n'
        end
        io << '\n'

        unless @children.empty?
          io << "Commands:".colorize.cyan << '\n'
          max_size = 4 + @children.keys.max_of &.size

          @children.each do |name, command|
            io << name
            io << " " * (max_size - name.size)
            io << command.summary << '\n'
          end

          io << '\n'
        end

        io << "Options:".colorize.cyan << '\n'
        max_size = 4 + @options.each.max_of { |name, opt| name.size + (opt.short ? 2 : 0) }

        @options.each do |name, option|
          if short = option.short
            io << '-' << short << ", "
          end
          io << "--" << name

          name_size = name.size + (option.short ? 4 : 0)
          io << " " * (max_size - name_size)
          io << option.description << '\n'
        end
      end
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
      @debug = true if options.has? "debug"
      Colorize.enabled = false if options.has? "no-color"

      if options.has? "help"
        stdout.puts help_template

        false
      else
        true
      end
    end
  end
end
