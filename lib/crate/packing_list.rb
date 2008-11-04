module Crate

  # encapsulate a packing list, a list of files and the prefix of those files
  # that need to be stripped off for doing require
  class PackingList

    attr_reader :prefix
    attr_reader :file_list

    def initialize( file_list, prefix = Dir.pwd )
      @prefix = prefix
      @file_list = file_list.collect { |f| File.expand_path(f) }
    end

  end
end
