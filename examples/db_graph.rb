require 'erb'
require 'sequel'

# Tasks to generate Entity-Relationship diagrams (in Graphviz DOT format)
# from either database schema or application-level Sequel models/associations.
#
# Note adapted from Jeremy Evans' and Rohit Namjoshi's son's code at 
#   http://sequel.heroku.com/2010/05/29/fun-with-graphviz-and-associations/
#
# Has not been extensively tested esp. for compound keys and many-to-many
# relationships.
#
module Db

  class Graph < Ing::Task
  
    desc "Generate E-R diagram in Graphviz DOT format"
    usage "  ing db:graph [SEQUEL-DATABASE-URI] > output.dot"
    usage "\nTo pipe directly to Graphviz:"
    usage "  ing db:graph [SEQUEL-DATABASE-URI] | dot -Tgif > output.gif"
    usage "\nTo graph model/associations rather than table/relations:"
    usage "  ing db:graph --models './models1.rb' --models './models2.rb'"

    opt :db,       "Sequel database URL (optional)", :type => :string
    opt :db_const, "Constant reference to database (optional)", 
        :type => :string, :default => 'DB'
    opt :label,    "Label for graph", :type => :string
    opt :models,   "Load models in file(s)", :type => :strings
    
    def models?; options[:models_given]; end
    def db?;     !!options[:db];     end
    def label;   options[:label_given] ? options[:label] : nil;  end
    
    def init_options(given)
      self.options = given
    end
    
    def call(url=nil)
      models? ? models : schema(url)
    end
    
    def schema(url=nil)
      url = (options[:db] ||= url)
      raise ArgumentError,
        "You must specify a database URL, or manually assign DB=" \
        unless url || (db = db_global)
      
      db ||= Sequel.connect(url)
      relations = []
      tables = []      
      db.tables.each do |t|
        next if t == :schema_info
        tables << Node.new(t, db[t].columns)
        fks = db.foreign_key_list(t)
        fks.each do |fk|
          # note assumes primary key == :id when key is nil
          relations << Edge.new(
                        t, 
                        :many_to_one, 
                        fk[:table], 
                        fk[:columns], 
                        fk[:key] || [:id]
                       )
        end
      end
      $stdout.puts to_dot(tables, relations, self.label)
    end
    
    def models
      Sequel::Model.plugin :subclasses
      options[:models].each do |f| require f end
      associations = []
      classes = []
      Sequel::Model.descendents.each do |c|
        next if c.name.empty?
        classes << Node.new(c.table_name, c.columns)
        c.associations.each do |a|
          ar = c.association_reflection(a)
          begin
            ac = ar.associated_class
          rescue NameError
            $stderr.puts "Couldn't get associated class for #{c}.#{ar[:type]} #{ar[:name].inspect}"
          else
            fr_cols, to_cols = 
              case ar[:type] 
              when :one_to_many, :one_to_one
                [ Array(ar[:primary_key] || [:id]), Array(ar[:key]) ]
              when :many_to_one
                [ Array(ar[:key]), Array(ar[:primary_key] || [:id]) ]
              when :many_to_many
                [ [nil], [nil] ]
              end
            associations << Edge.new(
                              c.table_name, 
                              ar[:type], 
                              ac.table_name,
                              fr_cols,
                              to_cols
                            )
          end
        end
      end
      $stdout.puts to_dot(classes, associations, self.label)      
    end
    
    private
    
    def db_global(const=options[:db_const])
      Object.const_get(const) rescue nil
    end
    
    def to_dot(nodes, edges, label=nil)
      lines = []
      lines << "digraph G {"
      lines << "node [shape=none,fontname=\"DejaVu Sans\"];"
      lines << "rankdir=LR;"
      lines << "fontname=\"DejaVu Sans, BOLD\";"
      lines << "fontsize=18;"
      if label
        lines << "label=\"#{label}\";" 
        lines << "labelloc=t;"
      end
      nodes.each do |node|
        lines << ERB.new(label_template).result(binding)
      end
      edges.each do |edge| 
        lines += edge.key_column_map.map { |(from_col, to_col)|
          "\"#{edge.from_table}\"" + (from_col ? ":\"#{from_col}\"" : "") +
          " -> " +
          "\"#{edge.to_table}\""   + (to_col ? ":\"#{to_col}\"" : "") +
          " [style=#{edge_styles[edge.type]}];"
        }
      end
      lines << "}"
      lines.join
    end
    
    def label_template
      @label_template ||= <<_____
<%= node.name %> [label=<
<table border="0" cellborder="1" cellspacing="0" cellpadding="4">
  <tr><td bgcolor="lightgrey" PORT="<%= node.name %>"><b><%= node.name.to_s.upcase %></b></td></tr>
  <% node.columns.each do |col| %>
  <tr><td PORT="<%= col %>"><%= col %></td></tr>
  <% end %>
</table>
>]      
_____
    end
    
    def edge_styles
      @edge_styles ||= {
        :many_to_one=>:bold, 
        :one_to_many=>:solid, 
        :many_to_many=>:dashed, 
        :one_to_one=>:dotted
      }
    end
    
  end
  
  class Node < Struct.new(:name, :columns)
  end
  
  class Edge < Struct.new(:from_table, :type, :to_table, 
                          :from_key_columns, :to_key_columns)
    
    def key_column_map
      from_key_columns.zip(to_key_columns)
    end
  end
  
end