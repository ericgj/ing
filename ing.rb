# Ing tasks
# Store your tasks in ./tasks and they will be available to `ing`.
# Or simply overwrite this file.

Dir[File.expand_path("examples/**/*.rb", File.dirname(__FILE__))].each do |rb|
  load rb
end
