require 'archive/tar/minitar'
require 'zlib'
require 'fileutils'
require 'rubygems/installer'
require 'net/ftp'
require 'net/http'

module Crate
  #
  # Utiltiy methods useful for many items
  module Utils

    def logger
      @logger ||= Logging::Logger['Crate::Utils']
    end
    extend self 

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
    # download the given URI to a specified location
    #
    def download( uri, to )
      to_dir = File.dirname( to )
      FileUtils.mkdir_p( to_dir ) unless File.directory?( to_dir )

      begin
        case uri
        when URI::FTP  : download_via_ftp( uri, to )
        when URI::HTTP : download_via_http( uri, to )
        else
          raise ::Crate::Error, "Downloading is only supported via FTP or HTTP at this time"
        end
      rescue => e
        puts
        STDERR.puts "Error downloading #{uri.to_s} : #{e}"
        exit 1
      end
    end


    # download vi FTP
    #
    def download_via_ftp( uri, to )
      Net::FTP.open( uri.host ) do |ftp|
        ftp.passive = true
        ftp.login
        ftp.getbinaryfile( uri.path, to )
      end
    end


    # download via HTTP, following redirects
    #
    def download_via_http( uri, to, limit = 10 )
      uri = URI.parse( uri ) unless URI === uri
      raise ::Crate::Error, "Reached HTTP Redirect limit with #{uri.to_s}" if limit == 0
      Net::HTTP.start( uri.host, uri.port ) do |http|
        http.request_get( uri.request_uri ) do |response|
          case response
          when Net::HTTPSuccess then
            Utils.logger.debug "success! saving to #{to}"
            File.open( to, "wb" ) do |outf|
              response.read_body { |bytes| outf.write bytes }
            end
          when Net::HTTPRedirection then
            Utils.logger.debug "redirect to #{response['location']}"
            download_via_http( response['location'], to, limit - 1 )
          else response.error!
          end
        end
      end
    end

    
    # Apply the given patch file in a particular directory
    #
    def apply_patch( patch_file, location )
      Dir.chdir( location ) do
        %x[ patch -p0 < #{patch_file} ]
      end
    end
  end
end
