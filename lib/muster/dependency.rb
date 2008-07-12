require 'rake'
require 'rake/tasklib'
require 'muster/utils'
require 'muster/digest'

module Muster
  # Create a build task that will download, checksum and build and install an
  # upstream source
  #
  # This task will create the following targets:
  #
  class Dependency < ::Rake::TaskLib
    include ::Muster::Utils
    # Name of the task, this is also the Rake namespace underwhich all other
    # tasks will follow
    attr_accessor :name

    # Version of the upstream version
    attr_accessor :version

    # Upstream location 
    attr_accessor :upstream_source

    # array of shell commands for building 
    attr_accessor :build_commands

    # array of shell commands for installing
    attr_accessor :install_commands

    #
    # Create a Muster Dependency with the given name and version
    #
    def initialize( name = nil, version = nil )
      @name = name
      @version = version
      @install_commands = []
      @build_commands = []
      yield self if block_given?
      @upstream_source = URI.parse( @upstream_source )
      define unless name.nil? or version.nil?
    end

    # 
    # The build directory for this particular task
    #
    def build_dir
      @build_dir ||= File.join(Muster.project.build_dir, name )
    end

    #
    # The recipe directory for this particular task
    #
    def recipe_dir
      @recipe_dir ||= File.join( Muster.project.recipe_dir, name )
    end

    #
    # The fake root directory to install into
    # 
    def install_dir
      Muster.project.install_dir
    end

    #
    # handle to the top level logger
    #
    def logger
      Muster.project.logger
    end

    #
    # The directory this task unpacks into
    #
    def pkg_dir
      @pkg_dir ||= File.join( self.build_dir, "#{name + ( version ? "-#{version}" : "" ) }" )
    end

    #
    # override the directory that the local source unpacks into if it is not
    # +name-version+
    #
    def pkg_dir=( pd )
      @pkg_dir = File.join( self.build_dir, pd )
    end

    #
    # The local on disk copy of the upstream source
    #
    def local_source
      @local_source ||= File.join( build_dir, File.basename( upstream_source.path ) )
    end

    #
    # record the upstream sha1 checksum
    #
    def upstream_sha1=( checksum )
      @digest = Muster::Digest.sha1( checksum )
    end
    def upstream_sha1; return @digest.hex; end

    #
    # record the upstream md5 checksum
    #
    def upstream_md5=( checksum )
      @digest = Muster::Digest.md5( checksum )
    end
    def usptream_md5; return @digest.hex; end

    #
    # Define all the tasks in the namespace of the +name+ of this task.
    #
    # The dependency chain is:
    #
    #   :install => :build => :integrate => :patch => :unpack => :verify => :download
    #
    #
    def define
      logger.debug "Defining tasks for #{name} #{version}"

      namespace name do

        file local_source do |t|
          logger.info "Downloading #{upstream_source} to #{t.name}"
          download( upstream_source, t.name )
        end

        desc "Download #{File.basename( local_source )}"
        task :download => local_source

        desc "Verify source against checksum #{@digest.hex}"
        task :verify => "#{name}:download" do 
          if @digest.valid?( local_source ) then
            logger.info "#{local_source} validates against #{@digest.hex}"
          else
            raise "#{local_source} does not have checksum #{@digest.hex}" 
          end
        end

        #-- unpack
        desc "Unpack #{name} into #{build_dir}"
        task :unpack => "#{name}:verify" do 
          logger.info "Unpacking"
          unpack( local_source, build_dir )
        end

        #-- patch
        desc "Apply patches to #{name}"
        task :patch => dotfile( 'patch' )  do
          logger.info "#{name} #{version} is patched"
        end
        file dotfile( 'patch' ) => "#{name}:unpack" do
          logger.info "Patching #{name} #{version}"
          patch_files.each do |pfile|
            logger.info "applying patch #{File.basename( pfile ) }"
            apply_patch( pfile, pkg_dir )
          end
          dotfile!( 'patch' )
        end

        #-- build
        desc "Build #{name} #{version}"
        task :build => dotfile( 'build' ) do
          logger.info "#{name} #{version} built"
        end

        file dotfile( 'build' ) => dotfile( 'patch' ) do
          logger.info "Bulding #{name} #{version}"
          Dir.chdir( pkg_dir ) do
            build
          end
          dotfile!( 'build' )
        end

        #-- install
        desc "Install #{name} into #{Muster.project.install_dir}"
        task :install => dotfile('install')  do
          logger.info "#{name} #{version} is installed"
        end

        file dotfile( 'install' ) => "#{name}:build" do 
          logger.info "Installing #{name} #{version}"
          Dir.chdir( pkg_dir ) do
            install
          end
          dotfile!( 'install' )
        end

        task :done    => "#{name}:install"
        task :default => "#{name}:done"
      end
      
      desc "Build and Install #{name} #{version}"
      task name => "#{name}:default"
    end

    #
    # Execute all the build commands
    #
    def build
      cd_and_sh( pkg_dir, build_commands )
    end

    #
    # Execute all the install commands
    #
    def install
      cd_and_sh( pkg_dir, install_commands )
    end

    #
    # Change to a directory and execute a sequence of commands
    #
    def cd_and_sh( dir, cmds )
      Dir.chdir( dir ) do
        cmds.each do |cmd|
          sh cmd
        end
      end
    end

    #
    # Execute a shell command, sending the command name to the logger at info
    # level and all the output to the logger at the debug level
    #
    def sh( cmd )
      logger.info( cmd )
      io = IO.popen( cmd )
      until io.eof? 
        logger.debug( io.readline.strip )
      end
    end

    #
    # return the full path to a named dotfile
    #
    def dotfile( name )
      File.join( build_dir, ".#{name}" )
    end

    #
    # make the given dotfile
    #
    def dotfile!( name )
      File.open( dotfile( name ), "w" ) do |f|
        h = { 'name' => self.name, 'version' => self.version, "#{name}_timestsamp" => Time.now }
        f.puts h.to_yaml
      end
    end

    #
    # allow this task to say it depends on something else.  This is a build
    # dependency 
    #
    def depends_on( other_dependency )
      namespace name do
        task :build => "#{other_dependency}:done"
      end
    end

    # 
    # patch the upacked source with files that are in the recipe directory
    #
    def patch_files
      Dir[File.join( recipe_dir, "*.patch" )].sort
    end
  end
end
