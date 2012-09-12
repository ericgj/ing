require 'fileutils'

module Gin

  module Shell
  
    class Basic
      attr_accessor :base
      attr_reader   :padding

      # Initialize base, mute and padding to nil.
      #
      def initialize #:nodoc:
        @base, @mute, @padding = nil, false, 0
      end

      # Check if base is muted
      #
      def mute?
        @mute
      end

      # Sets the output padding, not allowing less than zero values.
      #
      def padding=(value)
        @padding = [0, value].max
      end
      
      # Say (print) something to the user. If the sentence ends with a whitespace
      # or tab character, a new line is not appended (print + flush). Otherwise
      # are passed straight to puts (behavior got from Highline).
      #
      # ==== Example
      # say("I know you knew that.")
      #
      def say(message="", color=nil, force_new_line=(message.to_s !~ /( |\t)$/))
        message = message.to_s

        message = set_color(message, *color) if color

        spaces = "  " * padding

        if force_new_line
          stdout.puts(spaces + message)
        else
          stdout.print(spaces + message)
        end
        stdout.flush
      end

      # Say a status with the given color and appends the message. Since this
      # method is used frequently by actions, it allows nil or false to be given
      # in log_status, avoiding the message from being shown. If a Symbol is
      # given in log_status, it's used as the color.
      #
      def say_status(status, message, log_status=true)
        return if quiet? || log_status == false
        spaces = "  " * (padding + 1)
        color  = log_status.is_a?(Symbol) ? log_status : :green

        status = status.to_s.rjust(12)
        status = set_color status, color, true if color

        stdout.puts "#{status}#{spaces}#{message}"
        stdout.flush
      end


      # Apply color to the given string with optional bold. Disabled in the
      # Thor::Shell::Basic class.
      #
      def set_color(string, *args) #:nodoc:
        string
      end

      
      def debug(*args)
        stderr.puts *args
      end


      def quiet? #:nodoc:
        mute? || (base && base.options[:quiet])
      end

      def stdout
        $stdout
      end
      
      def stderr
        $stderr
      end
      
    end
  
  end
  
end