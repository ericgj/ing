# monkey patch for better ask behavior

class Thor
  module Shell
    class Basic
    
      def ask(statement, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        color = args.pop
        default = options[:default]
        if options[:limited_to] 
          ask_filtered(statement, options[:limited_to], color, default)
        else
          ask_simply(statement, color, default)
        end
      end
      
      def yes?(statement, *args)
        !!(ask(statement, *args) =~ is?(:yes))
      end     
      
      protected
      

      def ask_simply(statement, color=nil, default=nil)
        say("#{statement} #{default ? '(default ' + default + ')' : nil} ", color)
        input = stdin.gets.strip
        input.empty? ? default : input
      end

      def ask_filtered(statement, answer_set, color=nil, default=nil)
        correct_answer = nil
        until correct_answer
          answer = ask_simply("#{statement} #{answer_set.inspect}", color, default)
          correct_answer = answer_set.include?(answer) ? answer : nil
          answers = answer_set.map(&:inspect).join(", ")
          say("Your response must be one of: [#{answers}]. Please try again.") unless correct_answer
        end
        correct_answer
      end

    end
  end
end