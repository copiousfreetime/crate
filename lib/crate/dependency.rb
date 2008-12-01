require 'rake'
require 'rake/tasklib'
require 'rake/clean'
require 'crate/utils'
require 'crate/digest'

module Crate
  # Create a build task that will download, checksum and build and install an
  # upstream source
  #
  # This task will create the following targets:
  #
  class Dependency < ::Rake::TaskLib
    include ::Crate::Utils
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
    # Create a Crate Dependency with the given name and version
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
      @build_dir ||= File.join(Crate.project.build_dir, name )
    end

    #
    # The recipe directory for this particular task
    #
    def recipe_dir
      @recipe_dir ||= File.join( Crate.project.recipe_dir, name )
    end

    #
    # The fake root directory to install into
    # 
    def install_dir
      Crate.project.install_dir
    end

    #
    # handle to the top level logger
    #
    def logger
      Crate.project.logger
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
      @digest = Crate::Digest.sha1( checksum )
    end
    def upstream_sha1
      if @digest then
        return @digest.hex
      else
        return nil
      end
    end

    #
    # record the upstream md5 checksum
    #
    def upstream_md5=( checksum )
      @digest = Crate::Digest.md5( checksum )
    end
    def usptream_md5
      if @digest then
        return @digest.hex
      else
        return nil
      end
    end

    #
    # Define all the tasks in the namespace of the +name+ of this task.
    #
    # The dependency chain is:
    #
    #   :install => :build => :patch => :unpack => :verify => :download
    #
    #
    def define
      logger.debug "Defining tasks for #{name} #{version}"

      namespace "#{name}" do
        define_download
        define_verify
        define_unpack
        define_patch
        define_build
        define_install

        task :done    => "#{name}:install"
        task :default => "#{name}:done"
      end

      desc "Build and Install #{name} #{version}"
      task name => "#{name}:default"
    end

    def define_download
      file local_source do |t|
        logger.info "Downloading #{upstream_source} to #{t.name}"
        download( upstream_source, t.name )
      end

      desc "Download #{File.basename( local_source )}"
      task :download => local_source
    end

    def define_verify
      desc "Verify source against checksum #{@digest.hex}"
      task :verify => "#{name}:download" do 
        if @digest then 
          if @digest.valid?( local_source ) then
            logger.info "#{local_source} validates against #{@digest.hex}"
          else
            raise "#{local_source} does not have checksum #{@digest.hex}" 
          end
        else
          logger.info "#{local_source} has no validation check"
        end
      end
    end

    def define_unpack
      #-- unpack
      desc "Unpack #{name} into #{build_dir}"
      task :unpack => "#{name}:verify" do 
        logger.info "Unpacking"
        unpack( local_source, build_dir )
        FileUtils.rm_f dotfile( 'patch' )
      end
      ::CLEAN << pkg_dir
    end

    def define_patch
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

      ::CLEAN << dotfile( 'patch' )
    end

    def define_build
      desc "Build #{name} #{version}"
      task :build => dotfile( 'build' ) do
        logger.info "#{name} #{version} built"
      end

      file dotfile( 'build' ) => "#{name}:patch" do
        logger.info "Bulding #{name} #{version}"
        Dir.chdir( pkg_dir ) do
          build
        end
        dotfile!( 'build' )
      end
      ::CLEAN << dotfile( 'build' )
    end

    def define_install
      desc "Install #{name} into #{Crate.project.install_dir}"
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
      ::CLEAN << dotfile( 'install' )

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

      io = IO.popen( "#{cmd} 2>&1" )
      io.each_line do |l|
        logger.debug( l.strip )
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
