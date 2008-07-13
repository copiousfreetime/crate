require 'muster/dependency'
require 'muster/gem_integration'

module Muster
  class Ruby < Dependency
    #
    # Create a Muster Ruby  with the given name and version
    #
    def initialize( name = nil, version = nil )
      @name = name
      @version = version
      @install_commands = []
      @build_commands = []
      yield self if block_given?
      @upstream_source = URI.parse( @upstream_source )
      define unless name.nil? or version.nil?
      ::Muster.ruby = self
    end


    #
    # Define all the tasks in the namespace of the +name+ of this task.
    #
    # The dependency chain is:
    #
    #   :install => :build => :integration => :patch => :unpack => :verify => :download
    #
    #
    def define
      logger.debug "Defining tasks for #{name} #{version}"

      namespace name do
        define_download
        define_verify
        define_unpack
        define_patch
        define_integration

        define_build
        task :build => "#{name}:integration"

        define_install

        task :done    => "#{name}:install"
        task :default => "#{name}:done"
      end

      desc "Build and Integrate #{name} #{version}"
      task name => "#{name}:default"
    end

    def lib_dir
      File.join( pkg_dir, "lib" )
    end

    def ext_dir
      File.join( pkg_dir, "ext" )
    end

    def ext_setup_file
      File.join( ext_dir, "Setup" )
    end

    #
    # Add in an integration task that depends on all the Integeration object's
    # name:default task
    #
    def define_integration
      desc "Integrate ruby modules into final source" 
      task :integration => "#{name}:patch"
    end

    def integrates( other )
      task "#{name}:integration" => "#{other}:integration"
    end
  end
end
