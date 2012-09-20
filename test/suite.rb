Dir[ File.expand_path('{unit,actions,acceptance}/*.rb',
                      File.dirname(__FILE__))
   ].each do |f| 
    puts "Loading tests: #{f.gsub(Dir.pwd,'.')}"
    require f 
  end
