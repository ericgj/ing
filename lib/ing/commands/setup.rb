module Ing
  module Commands
  
    class Setup < Ing::Generator
    
      desc  "Set up a default ing.rb and tasks directory"
      usage "  ing setup"
      
      def initial_options(given)
        given[:dest]   ||= Dir.pwd
        given[:source] ||= File.dirname(__FILE__)
        given
      end
      
      # note manual shell setup because `ing setup` is not routed through 
      # `ing implicit` (boot)
      #
      def call
        setup_shell unless shell
        in_root do
          create_file     'ing.rb', <<_____
# Ing tasks
# Store your tasks in ./tasks and they will be available to `ing`.
# Or simply overwrite this file.

Dir[File.expand_path("tasks/**/*.rb", File.dirname(__FILE__))].each do |rb|
  require rb
end

_____
          empty_directory 'tasks'
        end
      end
      
      private
      def setup_shell
        self.shell = Ing::Shell::Color.new
      end
      
    end
    
  end
end