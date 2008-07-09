# Recipe is heavily inspired by HookGet 
#
#   http://github.com/chneukirchen/rubyports/tree/master/hook-get.rb
#
require 'open-uri'
require 'digest/md5'
require 'digest/sha1'
require 'progressbar'
require 'archive/tar/minitar'
require 'zlib'

module Assimilate
  class Recipe
    class ChecksumError < ::StandardError; end
    def self.run(file)
      new.run( file )
    end
    
    attr_reader :version
    attr_reader :name
    attr_reader :file
    attr_reader :build_dir
    attr_reader :build_commands
    attr_reader :install_commands
    attr_reader :dependencies
    attr_reader :pkg_dir
    attr_reader :uri
    attr_reader :local_source

    def initialize
      @build_commands   = []
      @install_commands = []
      @dependencies     = []
    end

    def run( file )
      @file = File.expand_path(file)
      @build_dir = File.join(Assimilate.project.build_dir, File.basename( file, ".recipe" ))
      FileUtils.mkdir_p self.build_dir, :verbose => true
      Dir.chdir( self.build_dir ) do
        self.instance_eval File.read(file), file, 1
        deploy
      end
      self
    end

    def log( msg )
      prefix = "%-15s" % "#{name}-#{version}"
      puts "#{prefix} => #{msg}"
    end


    def recipe_dir
      Assimilate.project.recipe_dir
    end

    def install_dir
      Assimilate.project.install_dir
    end

    def sh(*args)
      lambda do
        Dir.chdir( pkg_dir ) do
          log args.join(" ")
          system(*args)
        end
      end
    end

    def build(*args)
      @build_commands << sh(*args)
    end

    def install(*args) 
      @install_commands << sh(*args)
    end

    def source( url )
      @uri = URI.parse( url )
      @local_source = File.join( build_dir, File.basename( uri.path ) )
    end
    
    def package(name, version=nil)
      @name    = name
      @version = version
      @pkg_dir = File.join( self.build_dir, "#{name + ( version ? "-#{version}" : "" ) }" )
    end

    def depend(name, version)
      @dependencies << { 'name' => name, 'version' => version }
    end

    def md5( checksum )
      @checksum = [ ::Digest::MD5.new , checksum ]
    end

    def sha1( checksum )
      @checksum = [ ::Digest::SHA1.new, checksum ]
    end

    private

    def tar_gz(url)
      sh "curl -L #{url} | tar xz"
    end

    def tar_bz2(url)
      sh "curl -L #{url} | tar xj"
    end

    def gem(url)
      sh "mkdir -p #{pkg_dir} && curl -L #{url} | tar xO data.tar.gz | tar xzm -C #{pkg_dir}"
    end


    def installed?
      File.exist?( File.join( self.build_dir, ".installed" ) )
    end

    def deploy
      log "Installing recipe"
      satisfy_dependencies
      download_and_verify
      unpack
      patch
      log "Building"
      until @build_commands.empty?
        l = @build_commands.shift
        l.call
      end

      log "Installing into fakeroot"
      until @install_commands.empty?
        l = @install_commands.shift
        l.call
      end
      log "Marking installed"
      h = { 'name' => self.name, 'version' => self.version, 'installed_at' => Time.now }
      File.open( File.join( build_dir, ".installed") , "w") { |f| f.puts h.to_yaml }
    end


    def satisfy_dependencies
      installed = Assimilate.project.installed_recipes
      @dependencies.each do |dep|
        satisfied = false
        installed.each do |recipe|
          if (recipe['name'] == dep['name']) and  (dep['version'] == recipe['version'] ) then
            satisfied = true
            break
          end
        end
        unless satisfied
          log "Installing dependency #{dep['name']}"
          Recipe.run File.join( recipe_dir, dep['name'], "#{dep['name']}.recipe" )
        end
      end
    end


    def download_and_verify
      log "Downloading #{uri.to_s}"
      return if File.exist?( local_source ) and verify( :quiet => true ) 

      progress_bar = nil
      pbar = nil 
      File.open( local_source , "w" ) do |outf|
        uri.open( :content_length_proc => lambda { |t| pbar = ::ProgressBar.new( File.basename( local_source ), t ) if  t && 0 < t  },  
                  :progress_proc       => lambda { |s| pbar.set s if pbar } ) do |inf|
          outf.write inf.read
        end 
        puts
      end

      verify!
    end

    def verify( opts = {} )
      log "Verifiying" unless opts[:quiet]
      if @checksum and @checksum.size == 2 then
        digest = @checksum.first
        should_be = @checksum.last
        result = digest.hexdigest( IO.read( local_source ) )
        return should_be == result
      else 
        return true
      end
    end

    def verify!
      raise ChecksumError, "#{local_source} does not have the correct checksum" unless verify
    end

    def unpack
      log "Unpacking"
      FileUtils.rm_rf( pkg_dir ) if File.directory?( pkg_dir )
      if local_source.match( /\.tar\.gz\Z/ ) or local_source.match(/\.tgz\Z/) then
        tgz = Zlib::GzipReader.new( File.open( local_source, 'rb') )
        Archive::Tar::Minitar.unpack( tgz, build_dir )
      else
        raise UnsupportedFormatError, "Unable to extract files from #{File.basename( local_source)} -- unknown format"
      end
    end
    
    def patch
      log "Patching"
      Dir[File.join(recipe_dir, "*.patch")].sort.each do |pfile|
      end
    end
  end
end
