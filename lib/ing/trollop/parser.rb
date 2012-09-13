# Extensions to Trollop::Parser

module Trollop

  class Parser
    
    def educate_banner stream=$stdout
      width
      @order.select {|what, _| what == :text}.each do |what, opt|
        stream.puts wrap(opt)
      end
    end
    alias :educate_text :educate_banner
    
  end

end