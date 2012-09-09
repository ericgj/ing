# patch to access captures in gsub_file
# https://github.com/kentaroi/thor/commit/46b6d0b18a58eb8f7586e57eb633e96664fb1722
#
class Thor
  module Actions
    
    def gsub_file(path, flag, *args, &block)
      return unless behavior == :invoke
      config = args.last.is_a?(Hash) ? args.pop : {}

      path = File.expand_path(path, destination_root)
      say_status :gsub, relative_to_original_destination_root(path), config.fetch(:verbose, true)

      unless options[:pretend]
        content = File.binread(path)
        if block
          if block.arity == 1
            content.gsub!(flag, *args) { block.call($&) }
          else
            content.gsub!(flag, *args) { block.call(*$~) }
          end
        else
          content.gsub!(flag, *args)
        end
        File.open(path, 'wb') { |file| file.write(content) }
      end
    end

  end
end