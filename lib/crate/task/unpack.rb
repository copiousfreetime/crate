require 'rubygems'
require 'gem/installer'
module Crate
  class Task
    class Unpack < ::Crate::Task

      # The File to unpack
      config 'file'

      def initialize( *args )
        super
      end

      #
      # Changes into a directory and unpacks the archive.
      #
      def unpack( archive, into = Dir.pwd )
        Dir.chdir( into ) do 
          if archive.match( /\.tar\.gz\Z/ ) or archive.match(/\.tgz\Z/) then
            tgz = ::Zlib::GzipReader.new( File.open( local_source, 'rb') )
            ::Archive::Tar::Minitar.unpack( tgz, into )
          elsif archive.match( /\.gem\Z/ ) then
            subdir = File.basename( archive, ".gem" )
            Gem::Installer.new( archive ).unpack( subdir )
          else
            raise "Unable to extract files from #{File.basename( local_source)} -- unknown format"
          end
        end
      end

      def process( *args )
        logger.info "unpacking #{config[:file] || args.first}"  
        return 'here/there'
      end
    end
  end
end
