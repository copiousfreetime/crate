require 'archive/tar/minitar'
require 'zlib'
require 'open-uri'
require 'fileutils'
require 'progressbar'
require 'rubygems/installer'

module Mustard
  #
  # Utiltiy methods useful for many items
  module Utils
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

    #
    # Verify the given file against a digest value.  If the digest value is nil
    # then it is a no-op.
    #
    def verify( file, against = nil )
      return ( against ? against.verify( file ) : true )
    end

    #
    # download the given URI to a specified location, show progress with a
    # progress bar.
    #
    def download( uri, to )
      to_dir = File.dirname( to )
      FileUtils.mkdir_p( to_dir ) unless File.directory?( to_dir )

      pbar = nil 
      File.open( to , "w" ) do |outf|
        begin
          uri.open( :content_length_proc => lambda { |t| pbar = ::ProgressBar.new( File.basename( local_source ), t ) if  t && 0 < t  },  
                    :progress_proc       => lambda { |s| pbar.set s if pbar } ) do |inf|
            outf.write inf.read
          end 
        rescue => e
          puts
          STDERR.puts "Error downloading #{uri.to_s} : #{e}"
          exit 1
        end
      end
    end

    #
    # Apply the given patch file in a particular directory
    #
    def apply_patch( patch_file, location )
      Dir.chdir( location ) do
        %x[ patch -p0 < #{patch_file} ]
      end
    end

    #
    # Wrap a command sending its output to the the Mustard.project logger at the
    # debug level
    #
  end
end
